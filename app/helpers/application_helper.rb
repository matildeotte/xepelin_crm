module ApplicationHelper
  def clp_money(amount)
    number_to_currency(amount || 0, unit: "$", precision: 0, delimiter: ".", separator: ",")
  end

  def percent_value(value)
    "#{(value || 0).round(1)}%"
  end

  def status_badge(text, tone = "neutral")
    content_tag(:span, text, class: "badge badge-#{tone}")
  end

  def activation_badge(company)
    tone =
      if company.operating?
        "success"
      elsif company.reactivation_opportunity?
        "warning"
      elsif company.first_operation_opportunity?
        "info"
      else
        "neutral"
      end

    status_badge(Company.human_enum_name(:activation_state, company.activation_state), tone)
  end

  def risk_badge(risk_eligibility)
    return status_badge("Sin resultado de riesgo", "neutral") unless risk_eligibility

    tone =
      if risk_eligibility.eligible?
        "success"
      elsif risk_eligibility.in_review?
        "warning"
      elsif risk_eligibility.not_eligible?
        "danger"
      else
        "neutral"
      end

    status_badge(RiskEligibility.human_enum_name(:status, risk_eligibility.status), tone)
  end

  def invoice_status_badge(invoice)
    tone =
      if invoice.paid?
        "success"
      elsif invoice.pending?
        "warning"
      elsif invoice.overdue?
        "danger"
      else
        "neutral"
      end

    status_badge(Invoice.human_enum_name(:status, invoice.status), tone)
  end
end
