require 'test_helper'

class GenerateExpectedJobTest < ActiveJob::TestCase
  anacapabot_user = ENV['ANACAPABOT_USER']
  anacapabot_password = ENV['ANACAPABOT_PASSWORD']

  login = "#{anacapabot_user}:#{anacapabot_password}"

  grader_url = "https://#{login}@github.com/classroom-test-1/grader-lab00.git"

  expected_url = "https://#{login}@github.com/classroom-test-1/expected-lab00.git"

  GenerateExpectedJob.perform_now(grader_url,expected_url)
end
