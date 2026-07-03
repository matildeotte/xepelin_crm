class DebtorsController < ApplicationController
  def show
    @debtor = Debtor.find(params[:id])
    company_ids = current_user.companies.select(:id)

    @portfolio_invoices = @debtor
      .invoices
      .where(company_id: company_ids)
      .includes(:company, :payments)
      .order(:due_date)

    @global_xepelin_invoices = @debtor.invoices.xepelin.includes(:company, :payments).order(due_date: :desc)
    @pricing_agreements = @debtor.pricing_agreements.where(company_id: company_ids).includes(:company)
    @risk_eligibilities = @debtor.risk_eligibilities.where(company_id: company_ids).includes(:company).order(evaluated_at: :desc)
  end
end
