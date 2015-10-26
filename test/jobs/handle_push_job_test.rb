require 'test_helper'

class HandlePushJobTest < ActiveJob::TestCase
  url = "https://github.com/jolting/sample-repo.git"
  version = "72a17e85c0a94a6b5c40a04d13435d104c011215"

  grader_url = "https://github.com/jolting/anacapa-proposed-project-format.git"
  grader_version = "eb510af2fe2ac4a7a6613ca42a1d16cb81b6b07d"

  HandlePushJob.perform_now(url,version,grader_url,grader_version)
end
