

class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  def push(payload)
    # TODO: handle push webhook
  end

  def webhook_secret(payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
