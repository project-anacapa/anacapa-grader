class GradeReport

  attr_reader(:students)
  def initialize(organization, labname)
     repo_list = organization.user.github_client.organization_repositories(organization.name)

     @students = {}
     repo_list.each do |repo|
       name = repo[:name]
       Rails.application.config.logger.info name
       fields =  /grade-(.*)-(.*)/.match(name)
       Rails.application.config.logger.info fields

       Rails.application.config.logger.info fields != nil

       #Rails.application.config.logger.info fields[0] == labname


       if fields != nil and fields[1] == labname
         student = Student.find_by(user_name: fields[2])
         if student
           client = Octokit::Client.new(access_token: student.access_token,
           auto_paginate: true,
           client_id: Rails.application.secrets.email_github_client_id,
           client_secret: Rails.application.secrets.email_github_client_secret
           )
           Rails.application.config.logger.info student.access_token
           Rails.application.config.logger.info Rails.application.secrets.email_github_client_id
           Rails.application.config.logger.info Rails.application.secrets.email_github_client_secret

           Rails.application.config.logger.info student.access_token


#           Rails.application.config.logger.info client

           umail_addr = client.emails.find { |email| /.*@umail.ucsb.edu/ =~ email[:email]}
           @students[fields[2]] = umail_addr
         else
           Rails.application.config.logger.info "not found student"

           @students[fields[2]] = {email: nil, verified: false}
         end
         grade_json =  organization.user.github_client.contents(repo.full_name, :path => 'index.json')
         Rails.application.config.logger.info grade_json
         uri = URI(grade_json[:download_url])
         @students[fields[2]][:grade] = JSON.parse(Net::HTTP.get(uri))
       end
     end
  end
end
