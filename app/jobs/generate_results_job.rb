require 'net/ssh'
require 'net/scp'

class GenerateResultsJob < ActiveJob::Base
  include GraderHelper

  queue_as :default

  def perform(url, version, grader_url, results_url)
    Dir.mktmpdir do |dir|
      # use the directory...
      clone(grader_url, dir,"grader")

      git_results  = clone(results_url, dir,"results")
      begin
        git_results.remove('.',{:recursive =>  TRUE})
      rescue
      end

      clone_revision(url,version,dir,"student")

      testables = generate_results(dir)
      #Right now we only support one worker
      output_filename = "#{dir}/results/expected.json"
      File.open(output_filename, "w") do |file|
        file << JSON.pretty_generate(testables)
      end
      push(git_results)
    end
  end

end
