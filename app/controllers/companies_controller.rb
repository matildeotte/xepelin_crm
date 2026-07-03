class CompaniesController < ApplicationController
  before_action :set_current_month, only: %i[index show]

  def index
    @companies = current_user.companies.includes(:invoices, :risk_eligibilities).sort_by do |company|
      [
        company.operating? ? 0 : 1,
        -company.financed_amount(from: @current_month_start, to: @current_month_end)
      ]
    end
  end

  def show
    @company = current_user.companies.find(params[:id])

    @financed_invoices = @company.financed_invoices
                                 .includes(:debtor, :payments)
                                 .order(:due_date)

    @opportunity_invoices = @company.opportunity_invoices
                                    .includes(:debtor)
                                    .order(issue_date: :desc)

    @risk_eligibilities = @company.risk_eligibilities.includes(:debtor).order(evaluated_at: :desc)
    @latest_risk_eligibility = @company.risk_eligibilities.company_level.order(evaluated_at: :desc).first
    @overdue_financed_amount = @company.financed_invoices.overdue.sum(:amount)
    @interactions = @company.interactions.order(created_at: :desc)
    @interaction = Interaction.new
  end

  private

  def set_current_month
    @current_month_start = current_day.beginning_of_month
    @current_month_end = current_day.end_of_month
  end
end
