

class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  def push(payload)
    HandlePushJob.perform_later payload
  end

  def webhook_secret(payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
