

class GradesController < ApplicationController
  before_filter :authenticate_user! # we do not need devise authentication here
  #before_filter :fetch_user, :except => [:index, :create]
  def show
    github_user         = GitHubUser.new(current_user.github_client)
    grade = Grade.new(github_user.user,'lab00')
    respond_to do |formats|
      format.json { render json: grade }
      format.xml { render xml: grade }
    end
  end
end
