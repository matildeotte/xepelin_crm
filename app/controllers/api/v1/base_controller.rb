class Api::V1::BaseController < ApplicationController
  include Api::V1::Serializable

  skip_before_action :require_login
  skip_forgery_protection

  before_action :authenticate_api_user!

  private

  def authenticate_api_user!
    return if current_user.present?

    render json: { error: "unauthorized" }, status: :unauthorized
  end

  def current_month
    @current_month ||= current_day.beginning_of_month..current_day.end_of_month
  end

  def percentage(numerator, denominator)
    return 0 if denominator.to_f.zero?

    (numerator.to_f / denominator.to_f * 100).round(1)
  end
end
