class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create failure]

  def new; end

  def create
    user = User.from_google(request.env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to root_path
  end

  def failure
    redirect_to login_path, alert: "No se pudo autenticar. Intenta nuevamente."
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada correctamente."
  end
end
