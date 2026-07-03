class DashboardController < ApplicationController
  def index
    @companies = current_user.companies.includes(:invoices, :risk_eligibilities)
    @current_month = current_day.beginning_of_month..current_day.end_of_month

    @portfolio_count = @companies.size
    @operating_companies = @companies.select(&:operating?)
    @operating_rate = percentage(@operating_companies.size, @portfolio_count)

    @financed_amount = portfolio_invoices.xepelin.where(financed_on: @current_month).sum(:amount)
    @sii_volume = portfolio_invoices.where(issue_date: @current_month).sum(:amount)
    @share_of_wallet = percentage(@financed_amount, @sii_volume)
    @expansion_opportunity = [@sii_volume - @financed_amount, 0].max

    @unpaid_invoices = portfolio_invoices.xepelin.unpaid.includes(:company, :debtor).order(:due_date)
    @overdue_amount = @unpaid_invoices.overdue.sum(:amount)

    @growth_opportunities = @companies
      .select(&:operating?)
      .select { |company| company.sii_volume(from: @current_month.begin, to: @current_month.end).positive? }
      .sort_by { |company| -company.expansion_opportunity(from: @current_month.begin, to: @current_month.end) }
      .first(10)

    @top_financed_companies = @companies
      .sort_by { |company| -company.financed_amount(from: @current_month.begin, to: @current_month.end) }
      .first(10)

    @low_sow_opportunities = @companies
      .select { |company| company.sii_volume(from: @current_month.begin, to: @current_month.end).positive? }
      .sort_by { |company| [company.share_of_wallet(from: @current_month.begin, to: @current_month.end), -company.expansion_opportunity(from: @current_month.begin, to: @current_month.end)] }
      .first(10)

    @risk_constraints = RiskEligibility
      .joins(:company)
      .where(companies: { user_id: current_user.id }, status: RiskEligibility.statuses.values_at("in_review", "not_eligible"))
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
