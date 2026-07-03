# frozen_string_literal: true

class CompanyHealthScorePrompt
  CHILE_TIME_ZONE = "America/Santiago"

  def initialize(company, current_day: Time.find_zone!(CHILE_TIME_ZONE).today)
    @company = company
    @current_day = current_day
    @current_month = current_day.beginning_of_month..current_day.end_of_month
    @previous_month = current_day.prev_month.beginning_of_month..current_day.prev_month.end_of_month
  end

  def contents
    [
      {
        role: "user",
        parts: [
          {
            text: <<~PROMPT
              You are an AI assistant embedded in Xepelin's Growth CRM for Key Account Managers.

              Business context:
              - Xepelin finances invoices.
              - The KAM's goal is to maximize active clients and financed amount.
              - KAMs do not own collections or risk modeling, but they need to know whether risk/collections may block future operations.
              - SII-visible invoices are invoices observed through the client's tax authority scraper.
              - Share of Wallet (SOW) means Xepelin financed amount divided by total SII-visible invoice volume.
              - A good recommendation should push a concrete commercial action, not a passive report.

              Task:
              Analyze the company signals below and produce a validated customer health output.

              Output rules:
              - Return only JSON.
              - Use exactly these keys: health_score, churn_risk, summary, recommended_actions.
              - health_score must be an integer between 0 and 100.
              - churn_risk must be one of: low, medium, high.
              - summary must be written in Chilean Spanish, concise, and business-friendly.
              - recommended_actions must be written in Chilean Spanish.
              - recommended_actions must contain 3 to 5 concrete KAM actions.
              - Prioritize actions that can increase financed amount, improve SOW, unblock operation, or prevent churn.
              - Do not invent facts outside the provided data.

              Scoring guidance:
              - High score: recent Xepelin operations, healthy SOW, eligible risk outputs, low overdue exposure, clear expansion runway.
              - Medium score: some recent activity or SII opportunity, but low SOW, risk review, concentration, or weak cadence.
              - Low score: no recent operation, high overdue exposure, not eligible risk output, weak SII activity, or clear churn signals.

              Company data:
              #{JSON.pretty_generate(company_payload)}
            PROMPT
          }
        ]
      }
    ]
  end

  private

  attr_reader :company, :current_day, :current_month, :previous_month

  def company_payload
    {
      today: current_day.iso8601,
      company: company_attributes,
      current_month_metrics: metrics_for(current_month),
      previous_month_metrics: metrics_for(previous_month),
      risk_outputs: risk_outputs,
      collections_context: collections_context,
      debtor_concentration: debtor_concentration,
      sii_opportunities: sii_opportunities,
      recent_interactions: recent_interactions
    }
  end

  def company_attributes
    {
      legal_name: company.legal_name,
      tax_id: company.tax_id,
      sector: company.sector,
      created_at: company.created_at.to_date.iso8601,
      sii_connected_at: company.sii_connected_at&.to_date&.iso8601,
      commercial_state: company.activation_state,
      system_next_best_action: company.next_best_action,
      last_financed_on: company.last_financed_on&.iso8601
    }
  end

  def metrics_for(period)
    {
      financed_amount_clp: company.financed_amount(from: period.begin, to: period.end).to_f,
      sii_visible_volume_clp: company.sii_volume(from: period.begin, to: period.end).to_f,
      share_of_wallet_pct: company.share_of_wallet(from: period.begin, to: period.end).to_f,
      expansion_opportunity_clp: company.expansion_opportunity(from: period.begin, to: period.end).to_f,
      xepelin_invoice_count: company.financed_invoices.where(financed_on: period).count,
      sii_only_invoice_count: company.opportunity_invoices.where(issue_date: period).count
    }
  end

  def risk_outputs
    company
      .risk_eligibilities
      .includes(:debtor)
      .order(evaluated_at: :desc)
      .limit(8)
      .map do |risk|
        {
          scope: risk.debtor ? "debtor_relationship" : "company",
          debtor_name: risk.debtor&.legal_name,
          status: risk.status,
          risk_type: risk.risk_type,
          reason: risk.reason,
          evaluated_at: risk.evaluated_at.to_date.iso8601
        }
      end
  end

  def collections_context
    overdue_invoices = company.financed_invoices.overdue.includes(:debtor)

    {
      overdue_financed_amount_clp: overdue_invoices.sum(:amount).to_f,
      overdue_invoice_count: overdue_invoices.count,
      worst_overdue_days: overdue_invoices.map(&:days_overdue).max || 0,
      overdue_debtors: overdue_invoices.first(5).map do |invoice|
        {
          debtor_name: invoice.debtor.legal_name,
          amount_clp: invoice.amount.to_f,
          days_overdue: invoice.days_overdue
        }
      end
    }
  end

  def debtor_concentration
    total_amount = company.invoices.sum(:amount)
    grouped = company.invoices.includes(:debtor).group_by(&:debtor)
    top = grouped.map { |debtor, invoices| [debtor, invoices.sum(&:amount)] }.max_by { |_debtor, amount| amount }

    {
      top_debtor_concentration_pct: company.top_debtor_concentration.to_f,
      top_debtor_name: top&.first&.legal_name,
      total_visible_amount_clp: total_amount.to_f
    }
  end

  def sii_opportunities
    eligible_debtor_ids = company.risk_eligibilities.relationship_level.eligible.pluck(:debtor_id)

    company
      .opportunity_invoices
      .includes(:debtor)
      .where(issue_date: current_month, due_date: current_day..)
      .order(amount: :desc)
      .limit(8)
      .map do |invoice|
        {
          invoice_number: invoice.invoice_number,
          debtor_name: invoice.debtor.legal_name,
          amount_clp: invoice.amount.to_f,
          due_date: invoice.due_date.iso8601,
          debtor_is_risk_eligible: eligible_debtor_ids.include?(invoice.debtor_id)
        }
      end
  end

  def recent_interactions
    company
      .interactions
      .order(created_at: :desc)
      .limit(5)
      .map do |interaction|
        {
          kind: interaction.kind,
          summary: interaction.summary,
          created_at: interaction.created_at.to_date.iso8601
        }
      end
  end
end
