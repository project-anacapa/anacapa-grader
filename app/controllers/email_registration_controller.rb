class EmailRegistrationController < ApplicationController

  def register
     redirect_to "https://github.com/login/oauth/authorize?client_id=#{Rails.application.secrets.email_github_client_id}&scope=email"
  end

  def callback
    session_code = request.env['rack.request.query_hash']['code']
    result = Octokit.exchange_code_for_token(session_code,
      Rails.application.secrets.email_github_client_id,
      Rails.application.secrets.email_github_client_secret)
    access_token = result[:access_token]
    client = Octokit::Client.new(access_token: access_token,
      auto_paginate: true,
      client_id: Rails.application.secrets.email_github_client_id,
      client_secret: Rails.application.secrets.email_github_client_secret
      )
    user_name = client.user
    student.find_or_create_by user_name: user_name do
      student.access_token = access_token
    end
    student.save

  end
end
