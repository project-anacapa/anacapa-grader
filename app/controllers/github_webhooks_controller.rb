

class GithubWebhooksController < ActionController::Base
  include GithubWebhook::Processor

  def push(payload)

    url = payload["repository"]["url"]
    version = payload["head_commit"]["id"]

    path = URI.parse(url).path
    fields =  /\/(.+)\/(?:(.+)-)?(.*)-(.*)/.match(path)

    org = fields[1]

    if fields[2] == nil
      if fields[3] == 'grader'
        type = 'grader'
        project = fields[4]
      else
        type = 'submission'
        project = fields[3]
        user    = fields[4]
      end
    else
      type    = fields[2]
      project = fields[3]
      user    = fields[4]
    end



    organization = Organization.find_by name: org

    instructor_token = organization.user.token
    student_url      = "https://#{instructor_token}@github.com/#{org}/#{project}-#{user}.git"
    grader_repo    = "#{org}/grader-#{project}"
    grader_url     = "https://#{instructor_token}@github.com/#{grader_repo}.git"
    expected_repo    = "#{org}/expected-#{project}"
    expected_url     = "https://#{instructor_token}@github.com/#{expected_repo}.git"
    results_repo     = "#{org}/results-#{project}-#{user}"
    results_url      = "https://#{instructor_token}@github.com/#{results_repo}.git"

    Rails.application.config.logger.info type
    case type
    when 'results'
    when 'expected'
    when 'grader'
      Rails.application.config.logger.info "Does the repo exist: #{organization.user.github_client.repository?(expected_repo)}"

      if not organization.user.github_client.repository?(expected_repo)
        organization.user.github_client.create_repository(expected_repo)
      end
      GenerateExpectedJob.perform_later(grader_url,expected_url)
    when 'report'
    when 'submission'
      if not organization.user.github_client.repository?(results_repo)
        organization.user.github_client.create_repository(results_repo)
      end
      HandlePushJob.perform_later(student_url,version,expected_url,results_url)
    end

  end

  def webhook_secret(payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
