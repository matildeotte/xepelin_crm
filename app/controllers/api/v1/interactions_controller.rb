class Api::V1::InteractionsController < Api::V1::BaseController
  def create
    company = current_user.companies.find(params[:company_id])
    interaction = company.interactions.build(interaction_params)

    if interaction.save
      render json: { interaction: serialize_interaction(interaction) }, status: :created
    else
      render json: { errors: interaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def interaction_params
    params.require(:interaction).permit(:kind, :summary)
  end
end
