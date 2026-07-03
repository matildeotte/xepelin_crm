class SessionsController < ApplicationController
  skip_forgery_protection
  skip_before_action :require_login, only: %i[create failure destroy]

  def create
    user = User.from_google(request.env["omniauth.auth"])
    session[:user_id] = user.id

    redirect_to frontend_url, allow_other_host: true
  end

  def failure
    redirect_to frontend_url("/login?auth=failed"), allow_other_host: true
  end

  def destroy
    reset_session
    redirect_to frontend_url("/login"), allow_other_host: true
  end

  private

  def frontend_url(path = "")
    "#{ENV.fetch("FRONTEND_URL", "http://localhost:3001")}#{path}"
  end
end
