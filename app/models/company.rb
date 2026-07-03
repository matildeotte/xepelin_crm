class Company < ApplicationRecord
  belongs_to :user

  has_many :invoices, dependent: :destroy
  has_many :interactions, dependent: :destroy
  has_many :health_scores, dependent: :destroy
  has_many :pricing_agreements, dependent: :destroy
  has_many :risk_eligibilities, dependent: :destroy
  has_many :debtors, -> { distinct }, through: :invoices

  validates :legal_name, :tax_id, presence: true
  validates :tax_id, uniqueness: true

  def financed_invoices
    invoices.xepelin
  end

  def opportunity_invoices
    invoices.sii_only
  end

  def financed_amount(from: nil, to: nil)
    scoped = financed_invoices
    scoped = scoped.where(financed_on: from..) if from.present?
    scoped = scoped.where(financed_on: ..to) if to.present?
    scoped.sum(:amount)
  end

  def sii_volume(from: nil, to: nil)
    scoped = invoices
    scoped = scoped.where(issue_date: from..) if from.present?
    scoped = scoped.where(issue_date: ..to) if to.present?
    scoped.sum(:amount)
  end

  def share_of_wallet(from: nil, to: nil)
    total_visible_volume = sii_volume(from:, to:)
    return 0 if total_visible_volume.zero?

    (financed_amount(from:, to:).to_f / total_visible_volume * 100).round(1)
  end

  def expansion_opportunity(from: nil, to: nil)
    [sii_volume(from:, to:) - financed_amount(from:, to:), 0].max
  end

  def last_financed_on
    financed_invoices.maximum(:financed_on)
  end

  def operating?(days: 30)
    last_financed_on.present? && last_financed_on >= days.days.ago.to_date
  end

  def recent_sii_activity?(days: 30)
    invoices.where(issue_date: days.days.ago.to_date..Date.current).exists?
  end

  def activation_state
    return "operating" if operating?
    return "reactivation_opportunity" if last_financed_on.present? && recent_sii_activity?
    return "first_operation_opportunity" if last_financed_on.blank? && recent_sii_activity?

    "low_signal"
  end

  def activation_label
    {
      "operating" => "Operating",
      "reactivation_opportunity" => "Reactivate",
      "first_operation_opportunity" => "First operation",
      "low_signal" => "Low signal"
    }.fetch(activation_state)
  end

  def latest_health_score
    health_scores.order(generated_at: :desc).first
  end

  def latest_risk_eligibility
    risk_eligibilities.company_level.order(evaluated_at: :desc).first
  end

  def overdue_financed_amount
    financed_invoices.overdue.sum(:amount)
  end

  def top_debtor_concentration
    total = invoices.sum(:amount)
    return 0 if total.zero?

    top_debtor_amount = invoices.group(:debtor_id).sum(:amount).values.max || 0
    (top_debtor_amount.to_f / total * 100).round(1)
  end

  def next_best_action
    return "Review Risk output before pitching new operations" if latest_risk_eligibility&.not_eligible?
    return "Call to reactivate: recent SII activity with no recent Xepelin operation" if activation_state == "reactivation_opportunity"
    return "Pitch first Xepelin operation using recent SII invoices" if activation_state == "first_operation_opportunity"
    return "Expand wallet share: prioritize eligible debtor relationships" if share_of_wallet < 35

    "Maintain cadence and look for larger financed operations"
  end
end
