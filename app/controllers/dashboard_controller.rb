class DashboardController < ApplicationController
  def index
    @companies = current_user.companies.includes(:invoices, :risk_eligibilities)
    @current_month = Date.current.beginning_of_month..Date.current.end_of_month

    @portfolio_count = @companies.size
    @operating_companies = @companies.select(&:operating?)
    @operating_rate = percentage(@operating_companies.size, @portfolio_count)

    @financed_amount = portfolio_invoices.xepelin.where(financed_on: @current_month).sum(:amount)
    @sii_volume = portfolio_invoices.where(issue_date: @current_month).sum(:amount)
    @share_of_wallet = percentage(@financed_amount, @sii_volume)
    @expansion_opportunity = [@sii_volume - @financed_amount, 0].max

    @unpaid_invoices = portfolio_invoices.xepelin.unpaid.includes(:company, :debtor).order(:due_date)
    @overdue_amount = @unpaid_invoices.overdue.sum(:amount)

    @reactivation_opportunities = @companies
      .select { |company| %w[reactivation_opportunity first_operation_opportunity].include?(company.activation_state) }
      .sort_by { |company| -company.expansion_opportunity(from: Date.current.beginning_of_month, to: Date.current.end_of_month) }
      .first(10)

    @top_financed_companies = @companies
      .sort_by { |company| -company.financed_amount(from: Date.current.beginning_of_month, to: Date.current.end_of_month) }
      .first(10)

    @low_sow_opportunities = @companies
      .select { |company| company.sii_volume(from: Date.current.beginning_of_month, to: Date.current.end_of_month).positive? }
      .sort_by { |company| [company.share_of_wallet(from: Date.current.beginning_of_month, to: Date.current.end_of_month), -company.expansion_opportunity(from: Date.current.beginning_of_month, to: Date.current.end_of_month)] }
      .first(10)

    @risk_constraints = RiskEligibility
      .joins(:company)
      .where(companies: { user_id: current_user.id }, status: %w[in_review not_eligible])
      .includes(:company, :debtor)
      .order(evaluated_at: :desc)
      .first(10)
  end

  private

  def portfolio_invoices
    Invoice.joins(:company).where(companies: { user_id: current_user.id })
  end

  def percentage(numerator, denominator)
    return 0 if denominator.to_f.zero?

    (numerator.to_f / denominator.to_f * 100).round(1)
  end
end
