require 'test_helper'

class HandlePushJobTest < ActiveJob::TestCase
  url = "https://github.com/jolting/sample-repo.git"
  version = "72a17e85c0a94a6b5c40a04d13435d104c011215"

  grader_url = "https://github.com/jolting/anacapa-proposed-project-format.git"
  grader_version = "0312844ca23de62baeb40fa1d8ed97c0e484f36a"

  HandlePushJob.perform_now(url,version,grader_url,grader_version)
end
