
class Grade

  def initialize(user,assignment)
    results_url = "https://github.com/classroom-test-1/results-#{assignment}-#{user.name}.git"
    expected_url = "https://github.com/classroom-test-1/expected-#{assignment}.git"

    Dir.mktmpdir do |dir|
      Git.clone(results_url,  "results" , :path => dir)
      Git.clone(expected_url, "expected", :path => dir)

      @diff = Diffy::Diff.new("#{dir}/expected", "#{dir}/expected", :source => 'files')

    end

  end

end
