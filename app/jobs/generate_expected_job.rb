require 'net/ssh'
require 'net/scp'

class GenerateExpectedJob < ActiveJob::Base
  include GraderHelper
  queue_as :default

  def perform(grader_url,expected_url)
    Dir.mktmpdir do |dir|
      # use the directory...
      clone(grader_url, dir, "grader")

      git_expected = clone(expected_url, dir,"expected")
      begin
        git_expected.remove('.',{:recursive =>  TRUE})
      rescue
      end

      FileUtils.mv("#{dir}/grader/student_files","#{dir}/student")

      testables = generate_results(dir)
      #Right now we only support one worker
      output_filename = "#{dir}/expected/expected.json"
      File.open(output_filename, "w") do |file|
        file << JSON.pretty_generate(testables)
      end
      push(git_expected)
    end
  end



end
