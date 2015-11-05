

class GradesController < ApplicationController
#  before_filter :authenticate_user! # we do not need devise authentication here
  #before_filter :fetch_user, :except => [:index, :create]

  def index

  end

  def show

    @grade = Grade.new(current_user,current_user,params[:id])
    respond_to do |format|
      format.html
      format.json { render json: grade }
      format.xml { render xml: grade }
    end
  end
end
