class Api::V1::DebtorsController < Api::V1::BaseController
  def show
    company_ids = current_user.companies.select(:id)
    debtor = Debtor.joins(:invoices).where(invoices: { company_id: company_ids }).distinct.find(params[:id])
    portfolio_invoices = debtor
      .portfolio_xepelin_invoices(company_ids)
      .includes(:company, :payments)
      .order(:due_date)
    risk_eligibilities = debtor.risk_eligibilities.where(company_id: company_ids).includes(:company).order(evaluated_at: :desc)

    render json: {
      debtor: serialize_debtor(debtor, company_ids:),
      portfolio_invoices: portfolio_invoices.map { |invoice| serialize_invoice(invoice, include_company: true, include_debtor: false) },
      risk_eligibilities: risk_eligibilities.map { |risk| serialize_risk_eligibility(risk) }
    }
  end
end
