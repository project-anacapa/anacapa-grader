class GradeReport
  def initialize(organziation, labname)
     repo_list = organization.user.github_client.organization_repositories(organization.name)

     @students = {}
     repo_list.each do |repo|
       name = repo[:name]
       fields =  /grade-(.*)-(.*)/.match(name)
       if fields[0] == labname
         student = student.find_by_name(fields[1])
         if student
           client = Octokit::Client.new(access_token: student.access_token,
           auto_paginate: true,
           client_id: Rails.application.secrets.email_github_client_id,
           client_secret: Rails.application.secrets.email_github_client_secret
           )
           umail_addr = client.emails.find { |email| /.*@umail.ucsb.edu/ =~ email[:email]}
           @students[:fields[1]] = umail_addr
         else
           @students[:fields[1]] = {email: nil, verified: false}
         end
       end
     end
  end
end
