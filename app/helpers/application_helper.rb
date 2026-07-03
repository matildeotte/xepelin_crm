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
    tone = {
      "operating" => "success",
      "reactivation_opportunity" => "warning",
      "first_operation_opportunity" => "info",
      "low_signal" => "neutral"
    }.fetch(company.activation_state, "neutral")

    status_badge(company.activation_label, tone)
  end

  def risk_badge(risk_eligibility)
    return status_badge("No Risk output", "neutral") unless risk_eligibility

    tone = {
      "eligible" => "success",
      "in_review" => "warning",
      "not_eligible" => "danger"
    }.fetch(risk_eligibility.status, "neutral")

    status_badge(risk_eligibility.status.humanize, tone)
  end

  def invoice_status_badge(invoice)
    tone = {
      "paid" => "success",
      "pending" => "warning",
      "overdue" => "danger"
    }.fetch(invoice.status, "neutral")

    status_badge(invoice.status.humanize, tone)
  end
end
