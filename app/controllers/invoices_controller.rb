class InvoicesController < ApplicationController
  def unpaid
    @invoices = Invoice
      .xepelin
      .unpaid
      .joins(:company)
      .where(companies: { user_id: current_user.id })
      .includes(:company, :debtor, :payments)
      .order(:due_date)
  end
end
