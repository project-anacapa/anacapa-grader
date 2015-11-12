require 'test_helper'

class CreateGradeJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end
  CreateGradeJob.perform_now(url,version,grader_url,results_url)
end
