class CreateGradeJob < ActiveJob::Base
  queue_as :default

  def perform(results_url,expected_url,grade_url)
    grade = Grade.new(results_url,expected_url)
    Dir.mktmpdir do |dir|
      g = Git.clone(grade_url, "grade", :path => dir)
      begin
        g.remove('.',{:recursive =>  TRUE})
      rescue
      end


      readme = "#{dir}/grade/README.md"
      # probably should replace this with https://github.com/github/markup
      File.open(readme, "w") do |f|
        grade.testables.each do |testable_name, testable|
          f.write("##{testable_name}\n")
          if(testable[:status] == "graded")
            f.write("| test name ")
            f.write("| grade points ")
            f.write("| diff |\n")

            f.write("| ------------- | ------------- | ------------- |\n")


            testable[:testcases].each do |testcase_name, testcase|
              f.write("| #{testcase_name} ")
              f.write("| #{testcase[:grade_points]}/#{testcase[:out_of]}")
              f.write("| #{testcase[:diff].gsub!(/\n/, "")} |\n")
            end
          else
            f.write("<p>Build failure:</p>\n")
            f.write("```\n#{testable[:build_results]}\n```\n")
          end
          f.write("<p>Total Grade Points: #{testable[:total_grade_points]}/#{testable[:total_out_of]}</p>\n")

        end
      end
      push(g)

    end
  end

  def push(g)
    g.add(:all=>true)
    begin
      g.commit('grader', {:author=> "AnacapaBot <hunterlaux+anacapabot@gmail.com>"})
      g.push
    rescue
      #commit throws an exception if there is nothing to commit
    end
  end

end
