class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def current_day
    @current_day ||= Time.find_zone!("America/Santiago").today
  end

  def require_login
    render json: { error: "unauthorized" }, status: :unauthorized unless current_user
  end
end
