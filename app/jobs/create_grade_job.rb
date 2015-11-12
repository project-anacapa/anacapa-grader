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
      File.open(readme, "w") do |f|
        grade.testables.each do |testable_name, testable|
          f.write("##{testable_name}\n")
          f.write("| test name ")
          f.write("| grade ")
          f.write("| total points ")
          f.write("| diff |\n")

          f.write("| ------------- | ------------- | ------------- | ------------- |\n")

          testable.each do |testcase_name, testcase|
            f.write("| #{testcase_name} ")
            f.write("| #{testcase[:grade]} ")
            f.write("| #{testcase[:total_points]} ")
            f.write("| #{testcase[:diff].gsub!(/\n/, "")} |\n")
          end
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
