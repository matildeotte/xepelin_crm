class Debtor < ApplicationRecord
  has_many :invoices, dependent: :restrict_with_error
  has_many :companies, -> { distinct }, through: :invoices
  has_many :risk_eligibilities, dependent: :destroy

  validates :legal_name, :tax_id, presence: true
  validates :tax_id, uniqueness: true

  def invoices_for_user(user)
    invoices.joins(:company).where(companies: { user_id: user.id })
  end

  def portfolio_xepelin_invoices(company_ids)
    invoices.xepelin.where(company_id: company_ids)
  end

  def portfolio_outstanding_balance(company_ids)
    portfolio_xepelin_invoices(company_ids).unpaid.sum(:amount)
  end

  def portfolio_overdue_balance(company_ids)
    portfolio_xepelin_invoices(company_ids).overdue.sum(:amount)
  end

  def portfolio_pending_balance(company_ids)
    portfolio_xepelin_invoices(company_ids).pending.sum(:amount)
  end

  def portfolio_unpaid_xepelin_count(company_ids)
    portfolio_xepelin_invoices(company_ids).unpaid.count
  end
end
