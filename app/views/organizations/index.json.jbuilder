json.array!(@organizations) do |organization|
  json.extract! organization, :id, :name
  json.extract! organization.user.github_client.user, :login
  json.url organization_url(organization, format: :json)
end
