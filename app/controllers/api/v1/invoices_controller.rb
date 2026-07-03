class Api::V1::InvoicesController < Api::V1::BaseController
  def unpaid
    invoices = Invoice
      .xepelin
      .unpaid
      .joins(:company)
      .where(companies: { user_id: current_user.id })
      .includes(:company, :debtor, :payments)
      .order(:due_date)

    render json: {
      invoices: invoices.map { |invoice| serialize_invoice(invoice, include_company: true) }
    }
  end
end
