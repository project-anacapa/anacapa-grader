json.extract! @organization, :id, :name, :created_at, :updated_at
json.extract! @organization.user.github_client.user, :login
