require 'test_helper'

class HandlePushJobTest < ActiveJob::TestCase

  anacapabot_user = ENV['ANACAPABOT_USER']
  anacapabot_password = ENV['ANACAPABOT_PASSWORD']

  login = "#{anacapabot_user}:#{anacapabot_password}"

  url = "https://#{login}@github.com/classroom-test-1/lab00-jolting"
  # good version = "5216d68191ee813db2a08276186957a5a98cb724"
  version = "177875f615620f30f5c45128157231f2bdec2349"
  grader_url = "https://#{login}@github.com/classroom-test-1/grader-lab00.git"

  results_url = "https://#{login}@github.com/classroom-test-1/results-lab00-jolting.git"

  HandlePushJob.perform_now(url,version,grader_url,results_url)
end
