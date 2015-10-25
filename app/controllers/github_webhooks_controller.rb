

class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  def push(payload)
    url = payload["repository"]["url"]
    version = payload["head_commit"]["id"]

    #url = payload["repository"]["url"]
    #version = payload["head_commit"]["id"]
    HandlePushJob.perform_later(url,version,url,version)
  end

  def webhook_secret(payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
