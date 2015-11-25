
class Grade

  attr_reader :testables
  def initialize(results_url, expected_url)
    Dir.mktmpdir do |dir|
      Git.clone(results_url,  "results" , :path => dir)
      Git.clone(expected_url, "expected", :path => dir)

      @testables = process_testables(dir)

    end

  end

  def process_testables(dir)
    results_filename = "#{dir}/results/results.json"
    expected_filename = "#{dir}/expected/expected.json"
    results_testables = JSON.parse(File.read(results_filename))
    expected_testables = JSON.parse(File.read(expected_filename))

    grade = {}
    grade[:testables] = {}

    project_grade_points = 0
    project_out_of = 0

    testables = expected_testables["testables"].zip(expected_testables["testables"])
    testables.each do |expected, results|
      testable_results = generate_grade(expected,results)
      grade[:testables][expected["make_target"]] = testable_results
      project_grade_points += testable_results[:total_grade_points]
      project_out_of += testable_results[:total_out_of]

    end
    grade[:project_grade_points] = project_grade_points
    grade[:project_out_of] = project_out_of
    grade
  end

  #If a expected file doesn't exist generate one
  def generate_grade(expected,results)
    test = {}
    if expected["make_output"]["exit_code"] != 0
      test[:status]        = "build_failure"
      test[:build_results] = expected["make_output"]["make_output"]
    else
      test[:status]        = "graded"
      test[:build_results] = "" #no need for build results if it is graded
    end

    total_grade_points = 0
    total_out_of  = 0
    test[:testcases] = {}

    cases = expected["test_cases"].zip(results["test_cases"])
    cases.each do |e_case, r_case|
      diff = Diffy::Diff.new(e_case["output"], r_case["output"], :source => 'strings')

      if diff.to_a != []
        grade_points = 0
        diff_string = diff.to_s(:html)
      else
        grade_points = e_case['points']
        diff_string  = ""
      end
      out_of = e_case['points']
      test[:testcases][e_case["command"]] =
      {
          :grade_points  => grade_points,
          :out_of        => out_of,
          :diff          => diff_string
      }
      total_grade_points += grade_points
      total_out_of       += out_of
    end
    test[:total_grade_points] = total_grade_points
    test[:total_out_of] = total_out_of
    test
  end
end
