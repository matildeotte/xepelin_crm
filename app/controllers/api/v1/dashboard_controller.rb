class Api::V1::DashboardController < Api::V1::BaseController
  def show
    companies = current_user.companies.includes(:invoices, :risk_eligibilities)
    operating_companies = companies.select(&:operating?)
    financed_amount = portfolio_invoices.xepelin.where(financed_on: current_month).sum(:amount)
    sii_volume = portfolio_invoices.where(issue_date: current_month).sum(:amount)
    unpaid_invoices = portfolio_invoices.xepelin.unpaid.includes(:company, :debtor, :payments).order(:due_date)
    overdue_amount = unpaid_invoices.overdue.sum(:amount)
    risk_unlocked_opportunities = unlocked_opportunities_by_risk

    render json: {
      metrics: {
        portfolio_count: companies.size,
        operating_companies_count: operating_companies.size,
        operating_rate: percentage(operating_companies.size, companies.size),
        financed_amount: financed_amount.to_f,
        monthly_goal_amount: monthly_goal_amount.to_f,
        monthly_goal_progress: percentage(financed_amount, monthly_goal_amount),
        sii_volume: sii_volume.to_f,
        share_of_wallet: percentage(financed_amount, sii_volume),
        expansion_opportunity: [sii_volume - financed_amount, 0].max.to_f,
        eligible_expansion_pipeline: risk_unlocked_opportunities.sum { |opportunity| opportunity[:available_amount] }.to_f,
        unpaid_invoices_count: unpaid_invoices.size,
        overdue_amount: overdue_amount.to_f
      },
      growth_opportunities: growth_opportunities(companies),
      top_financed_companies: top_financed_companies(companies),
      low_sow_opportunities: low_sow_opportunities(companies),
      risk_unlocked_opportunities: risk_unlocked_opportunities,
      unpaid_invoices: unpaid_invoices.first(5).map { |invoice| serialize_invoice(invoice, include_company: true) }
    }
  end

  private

  def portfolio_invoices
    Invoice.joins(:company).where(companies: { user_id: current_user.id })
  end

  def monthly_goal_amount
    BigDecimal(ENV.fetch("MONTHLY_FINANCING_GOAL_CLP", "300000000"))
  end

  def growth_opportunities(companies)
    companies
      .select(&:operating?)
      .select { |company| company.sii_volume(from: current_month.begin, to: current_month.end).positive? }
      .sort_by { |company| -eligible_expansion_opportunity(company, from: current_month.begin, to: current_month.end) }
      .first(10)
      .map { |company| serialize_company_summary(company) }
  end

  def top_financed_companies(companies)
    companies
      .sort_by { |company| -company.financed_amount(from: current_month.begin, to: current_month.end) }
      .first(10)
      .map { |company| serialize_company_summary(company) }
  end

  def low_sow_opportunities(companies)
    companies
      .select { |company| company.sii_volume(from: current_month.begin, to: current_month.end).positive? }
      .sort_by do |company|
        [
          company.share_of_wallet(from: current_month.begin, to: current_month.end),
          -company.expansion_opportunity(from: current_month.begin, to: current_month.end)
        ]
      end
      .first(10)
      .map { |company| serialize_company_summary(company) }
  end

  def unlocked_opportunities_by_risk
    RiskEligibility
      .joins(:company)
      .where(companies: { user_id: current_user.id })
      .relationship_level
      .eligible
      .includes(:company, :debtor)
      .order(evaluated_at: :desc)
      .filter_map do |risk|
        invoices = risk
          .company
          .opportunity_invoices
          .where(debtor_id: risk.debtor_id, issue_date: current_month, due_date: current_day..)

        available_amount = invoices.sum(:amount)
        next unless available_amount.positive?

        {
          id: risk.id,
          company: serialize_company_link(risk.company),
          debtor: serialize_debtor_link(risk.debtor),
          available_amount: available_amount.to_f,
          invoice_count: invoices.count,
          evaluated_at: serialize_date(risk.evaluated_at),
          action: "Ofrecer línea",
          secondary_action: "Notificar por WhatsApp"
        }
      end
      .sort_by { |opportunity| -opportunity[:available_amount] }
      .first(10)
  end
end
