class HandlePushJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    payload = *args
    config.logger.info args
    dir = Dir.mktmpdir
    begin
      # use the directory...
      g = Git.clone(payload.head_commit.url, 'workspace', :path => dir)
      g.checkout(payload.head_commit.id)
      config.logger.info Dir.entries(dir)
    ensure
      # remove the directory.
      FileUtils.remove_entry dir
    end
    # Do something later
  end
end
