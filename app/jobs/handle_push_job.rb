class HandlePushJob < ActiveJob::Base
  queue_as :default

  def perform(payload)
    #logger = Logger.new(STDOUT)
    logger.info payload
    url = payload[:head_commit][:url]
    logger.info url
    dir = Dir.mktmpdir
    begin
      # use the directory...
      g = Git.clone(url, 'workspace', :path => dir)
      g.checkout(payload[:head_commit][:id])
      logger.info Dir.entries(dir)
    ensure
      # remove the directory.
      #FileUtils.remove_entry dir
    end
    # Do something later
  end
end
