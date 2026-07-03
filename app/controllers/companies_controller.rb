class CompaniesController < ApplicationController
  def index
    @companies = current_user.companies.includes(:invoices, :risk_eligibilities).sort_by do |company|
      [
        company.activation_state == "operating" ? 0 : 1,
        -company.financed_amount(from: Date.current.beginning_of_month, to: Date.current.end_of_month)
      ]
    end
  end

  def show
    @company = current_user.companies.find(params[:id])
    @current_month_start = Date.current.beginning_of_month
    @current_month_end = Date.current.end_of_month

    @financed_invoices = @company
      .financed_invoices
      .includes(:debtor, :payments)
      .order(:due_date)

    @opportunity_invoices = @company
      .opportunity_invoices
      .includes(:debtor)
      .order(issue_date: :desc)

    @pricing_agreements = @company.pricing_agreements.includes(:debtor).order(:monthly_rate)
    @risk_eligibilities = @company.risk_eligibilities.includes(:debtor).order(evaluated_at: :desc)
    @interactions = @company.interactions.order(created_at: :desc)
    @interaction = Interaction.new
  end

  def update
    @company = current_user.companies.find(params[:id])

    if @company.update(company_params)
      redirect_to @company, notice: "Company updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:notes)
  end
end
