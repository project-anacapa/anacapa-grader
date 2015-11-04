

class GradesController < ApplicationController
#  before_filter :authenticate_user! # we do not need devise authentication here
  #before_filter :fetch_user, :except => [:index, :create]
  def show

    grade = Grade.new(current_user,current_user,'lab00')
    respond_to do |format|
      format.json { render json: grade }
      format.xml { render xml: grade }
    end
  end
end
