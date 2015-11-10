
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
    grade
  end

  #If a expected file doesn't exist generate one
  def generate_grade(testable_path,result_path)
    test = {}
    Dir.foreach(testable_path) do |file|
      next if file == '.' || file == '..'
      testcase_path = "#{testable_path}/#{file}"
      testcase_name = file
      if File.directory?(testcase_path)
        expected_filename = "#{testcase_path}/expected_file"
        result_filename = "#{result_path}/#{testcase_name}"
        diff = Diffy::Diff.new( result_filename,expected_filename, :source => 'files')

        test[testcase_name] =
        {
          :grade => 10,
          :total_points => 10,
          :diff => diff.to_s(:text)
        }
      end
    end
    test
  end
end
