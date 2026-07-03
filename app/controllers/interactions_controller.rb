class InteractionsController < ApplicationController
  def create
    company = current_user.companies.find(params[:company_id])
    interaction = company.interactions.build(interaction_params)

    if interaction.save
      redirect_to company, notice: "Interaction added."
    else
      redirect_to company, alert: interaction.errors.full_messages.to_sentence
    end
  end

  private

  def interaction_params
    params.require(:interaction).permit(:kind, :summary)
  end
end
