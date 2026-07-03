class Api::V1::SessionsController < Api::V1::BaseController
  def show
    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        avatar_url: current_user.avatar_url
      }
    }
  end
end
