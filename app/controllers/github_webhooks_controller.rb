

class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  def push(payload)

    url = payload["repository"]["url"]
    version = payload["head_commit"]["id"]

    path = URI.parse(url).path
    fields =  /\/(.+)\/(?:(.+)-)?(.*)-(.*)/.match(path)
    org = fields[0]
    type = fields[1]
    project = fields[2]
    user = fields[3]

    organization = Organization.find_by name: org

    instructor_token = organization.user.token
    student_url      = "https://#{instructor_token}@github.com/#{org}/#{project}-#{user}"
    expected_url     = "https://#{instructor_token}@github.com/#{org}/expected-#{project}"
    results_repo     = "#{org}/results-#{project}-#{user}"
    results_url      = "https://#{instructor_token}@github.com/#{results_repo}"

    case type
    when 'results'
    when 'expected'
    when 'grader'
    when 'report'
    else
      if(organization.user.github_client.repositories.repository?(results_repo))
        organization.user.github_client.repositories.create_repository(results_repo)
      end
      HandlePushJob.perform_later(student_url,version,expected_url,results_url)
    end

  end

  def webhook_secret(payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
