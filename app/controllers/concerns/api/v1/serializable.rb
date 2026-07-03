module Api::V1::Serializable
  private

  def serialize_company_summary(company, from: current_month.begin, to: current_month.end)
    latest_risk_eligibility = company.risk_eligibilities.company_level.order(evaluated_at: :desc).first

    {
      id: company.id,
      legal_name: company.legal_name,
      tax_id: company.tax_id,
      sector: company.sector,
      created_at: serialize_date(company.created_at),
      sii_connected_at: serialize_date(company.sii_connected_at),
      activation_state: serialize_company_activation_state(company),
      next_best_action: serialize_company_next_best_action(company),
      latest_risk_eligibility: serialize_risk_eligibility(latest_risk_eligibility),
      metrics: serialize_company_metrics(company, from:, to:)
    }
  end

  def serialize_company_detail(company, from: current_month.begin, to: current_month.end)
    serialize_company_summary(company, from:, to:).merge(
      risk_eligibilities: company.risk_eligibilities.order(evaluated_at: :desc).map { |risk| serialize_risk_eligibility(risk) },
      financed_invoices: company.financed_invoices.includes(:debtor, :payments).order(:due_date).map { |invoice| serialize_invoice(invoice) },
      opportunity_invoices: company.opportunity_invoices.includes(:debtor).order(issue_date: :desc).map do |invoice|
        eligibility = company.risk_eligibilities.relationship_level.detect { |risk| risk.debtor_id == invoice.debtor_id }

        serialize_invoice(invoice).merge(suggested_action: suggested_invoice_action(eligibility))
      end,
      interactions: company.interactions.order(created_at: :desc).map { |interaction| serialize_interaction(interaction) }
    )
  end

  def serialize_company_metrics(company, from:, to:)
    {
      financed_amount: company.financed_amount(from:, to:).to_f,
      sii_volume: company.sii_volume(from:, to:).to_f,
      share_of_wallet: company.share_of_wallet(from:, to:).to_f,
      expansion_opportunity: company.expansion_opportunity(from:, to:).to_f,
      top_debtor_concentration: company.top_debtor_concentration.to_f,
      last_financed_on: serialize_date(company.last_financed_on)
    }
  end

  def serialize_company_activation_state(company)
    {
      value: company.activation_state,
      label: Company.human_enum_name(:activation_state, company.activation_state),
      tone: company_activation_tone(company)
    }
  end

  def serialize_company_next_best_action(company)
    {
      value: company.next_best_action,
      label: Company.human_enum_name(:next_best_action, company.next_best_action)
    }
  end

  def serialize_debtor(debtor)
    {
      id: debtor.id,
      legal_name: debtor.legal_name,
      tax_id: debtor.tax_id,
      sector: debtor.sector,
      payment_probability: {
        value: debtor.payment_probability,
        label: debtor.payment_probability_label
      },
      metrics: {
        xepelin_invoice_count: debtor.xepelin_invoice_count,
        global_financed_amount: debtor.global_financed_amount.to_f,
        open_exposure: debtor.open_exposure.to_f,
        on_time_payment_rate: debtor.on_time_payment_rate&.to_f
      }
    }
  end

  def serialize_invoice(invoice, include_company: false, include_debtor: true)
    {
      id: invoice.id,
      invoice_number: invoice.invoice_number,
      amount: invoice.amount.to_f,
      issue_date: serialize_date(invoice.issue_date),
      due_date: serialize_date(invoice.due_date),
      financed_on: serialize_date(invoice.financed_on),
      paid_on: serialize_date(invoice.paid_on),
      assigned: invoice.assigned,
      assignment_date: serialize_date(invoice.assignment_date),
      moratory_monthly_rate: invoice.moratory_monthly_rate.to_f,
      days_overdue: invoice.days_overdue,
      source: {
        value: invoice.source,
        label: Invoice.human_enum_name(:source, invoice.source)
      },
      status: {
        value: invoice.status,
        label: Invoice.human_enum_name(:status, invoice.status),
        tone: invoice_status_tone(invoice)
      },
      debtor_response_status: {
        value: invoice.debtor_response_status,
        label: Invoice.human_enum_name(:debtor_response_status, invoice.debtor_response_status)
      },
      company: include_company ? serialize_company_link(invoice.company) : nil,
      debtor: include_debtor ? serialize_debtor_link(invoice.debtor) : nil
    }
  end

  def serialize_risk_eligibility(risk_eligibility)
    return nil unless risk_eligibility

    {
      id: risk_eligibility.id,
      reason: risk_eligibility.reason,
      evaluated_at: serialize_date(risk_eligibility.evaluated_at),
      status: {
        value: risk_eligibility.status,
        label: RiskEligibility.human_enum_name(:status, risk_eligibility.status),
        tone: risk_eligibility_tone(risk_eligibility)
      },
      risk_type: {
        value: risk_eligibility.risk_type,
        label: RiskEligibility.human_enum_name(:risk_type, risk_eligibility.risk_type)
      },
      company: risk_eligibility.company ? serialize_company_link(risk_eligibility.company) : nil,
      debtor: risk_eligibility.debtor ? serialize_debtor_link(risk_eligibility.debtor) : nil
    }
  end

  def serialize_interaction(interaction)
    {
      id: interaction.id,
      summary: interaction.summary,
      created_at: serialize_date(interaction.created_at),
      kind: {
        value: interaction.kind,
        label: Interaction.human_enum_name(:kind, interaction.kind)
      }
    }
  end

  def serialize_company_link(company)
    {
      id: company.id,
      legal_name: company.legal_name,
      tax_id: company.tax_id
    }
  end

  def serialize_debtor_link(debtor)
    {
      id: debtor.id,
      legal_name: debtor.legal_name,
      tax_id: debtor.tax_id
    }
  end

  def company_activation_tone(company)
    return "success" if company.operating?
    return "warning" if company.reactivation_opportunity?
    return "info" if company.first_operation_opportunity?

    "neutral"
  end

  def risk_eligibility_tone(risk_eligibility)
    return "success" if risk_eligibility.eligible?
    return "warning" if risk_eligibility.in_review?
    return "danger" if risk_eligibility.not_eligible?

    "neutral"
  end

  def invoice_status_tone(invoice)
    return "success" if invoice.paid?
    return "warning" if invoice.pending?
    return "danger" if invoice.overdue?

    "neutral"
  end

  def suggested_invoice_action(eligibility)
    return "Esperar a riesgos: #{eligibility.reason}" if eligibility&.not_eligible?
    return "Hacer seguimiento con riesgos antes de ofrecer." if eligibility&.in_review?

    "Ofrecer financiamiento para esta relación con pagador."
  end

  def serialize_date(value)
    return nil if value.blank?

    value.respond_to?(:iso8601) ? value.iso8601 : value.to_s
  end
end
