class HandlePushJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    config.logger.info args
    # Do something later
  end
end
