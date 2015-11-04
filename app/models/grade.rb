
class Grade

  def initialize(user,owner,assignment)
    github_user = GitHubUser.new(user.github_client)

    results_url = "https://#{owner.token}@github.com/classroom-test-1/results-#{assignment}-#{github_user.user.login}.git"
    expected_url = "https://#{owner.token}@github.com/classroom-test-1/expected-#{assignment}.git"

    Dir.mktmpdir do |dir|
      Git.clone(results_url,  "results" , :path => dir)
      Git.clone(expected_url, "expected", :path => dir)

      @diff = Diffy::Diff.new("#{dir}/expected", "#{dir}/expected", :source => 'files')

    end

  end

end
