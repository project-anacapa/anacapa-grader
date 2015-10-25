require 'test_helper'

class HandlePushJobTest < ActiveJob::TestCase
  url = "https://github.com/classroom-test-1/lab00-jolting"
  version = "5a400ca38eeea897fbb8da56097a4eda4e6e226b"

  grader_url = "https://github.com/jolting/anacapa-proposed-project-format.git"
  grader_version = "eb510af2fe2ac4a7a6613ca42a1d16cb81b6b07d"

  HandlePushJob.perform_now(url,version,grader_url,grader_version)
end
