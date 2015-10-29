require 'test_helper'

class HandlePushJobTest < ActiveJob::TestCase

  anacapabot_user = ENV['ANACAPABOT_USER']
  anacapabot_password = ENV['ANACAPABOT_PASSWORD']

  login = "#{anacapabot_user}:#{anacapabot_password}"

  url = "https://github.com/jolting/sample-repo.git"
  version = "72a17e85c0a94a6b5c40a04d13435d104c011215"

  grader_url = "https://github.com/jolting/anacapa-proposed-project-format.git"
  #grader_version = "0312844ca23de62baeb40fa1d8ed97c0e484f36a"

  results_url = "https://#{login}@github.com/jolting/anacapa-results.git"

  HandlePushJob.perform_now(url,version,grader_url,results_url)
end
