
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
    grade = {}
    testables_path = "#{dir}/expected/testables"

    Dir.foreach(testables_path) do |file|
    next if file == '.' || file == '..'
      testable_path = "#{testables_path}/#{file}"
      testable_name = file
      result_path = "#{dir}/results/#{testable_name}"
      if File.directory?(testable_path)
        grade[testable_name] = generate_grade(testable_path,result_path)
      end
    end
  end

  #If a expected file doesn't exist generate one
  def generate_grade(testable_path,result_path)
    test = {}
    build_results_file = "#{result_path}/build_results"
    if File.exists?(build_results_file)
      file = File.open(build_results_file, "r")
      test[:status]        = "build_failure"
      test[:build_results] = file.read
    else
      test[:status]        = "graded"
      test[:build_results] = "" #no need for build results if it is graded
    end

    total_grade_points = 0
    total_out_of  = 0

    Dir.foreach(testable_path) do |file|
      next if file == '.' || file == '..'
      testcase_path = "#{testable_path}/#{file}"
      testcase_name = file
      if File.directory?(testcase_path)
        json_filename = "#{testcase_path}/index.json"
        testcase = JSON.parse(File.read(json_filename))
        if(test[:status] == "graded")
          expected_filename = "#{testcase_path}/expected_file"
          result_filename = "#{result_path}/#{testcase_name}"
          diff = Diffy::Diff.new( result_filename,expected_filename, :source => 'files')
          grade_points = testcase ['points']
          if diff.to_a != []
            grade_points = 0
          end
          diff_string = diff.to_s(:html)
        else
          grade_points = 0
          diff_string  = ""
        end
        out_of = testcase['points']
        test[:testcases][testcase_name] =
        {
          :grade_points  => grade_points,
          :out_of        => out_of,
          :diff          => diff_string
        }
        total_grade_points += grade_points
        total_out_of       += out_of
      end
    end
    test[:total_grade_points] = total_grade_points
    test[:total_out_of] = total_grade_points
    test
  end
end
