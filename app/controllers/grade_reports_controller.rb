class GradeReportsController < ApplicationController
  before_action :set_grade_report, only: [:show]

  # GET /organizations/1
  # GET /organizations/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_grade_report
      @organization = Organization.find_by(id: params[:organization_id])
      @grade_report = GradeReport.new(@organization, params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def grade_report_params
      params[:grade_report]
    end
end
