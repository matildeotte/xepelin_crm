class Company < ApplicationRecord
  belongs_to :user

  has_many :invoices, dependent: :destroy
  has_many :interactions, dependent: :destroy
  has_many :health_scores, dependent: :destroy
  has_many :pricing_agreements, dependent: :destroy
  has_many :risk_eligibilities, dependent: :destroy
  has_many :debtors, -> { distinct }, through: :invoices

  enum :activation_state, %i[operating reactivation_opportunity first_operation_opportunity low_signal]
  enum :next_best_action, %i[review_risk reactivate first_operation expand_wallet_share maintain_cadence]

  before_validation :assign_commercial_state

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

  def top_debtor_concentration
    total = invoices.sum(:amount)
    return 0 if total.zero?

    top_debtor_amount = invoices.group(:debtor_id).sum(:amount).values.max || 0
    (top_debtor_amount.to_f / total * 100).round(1)
  end

  def refresh_commercial_state!
    assign_commercial_state
    save!
  end

  private

  def assign_commercial_state
    self.activation_state = calculated_activation_state
    self.next_best_action = calculated_next_best_action
  end

  def calculated_activation_state
    return :operating if operated_recently?
    return :reactivation_opportunity if last_financed_on.present? && recent_sii_activity?
    return :first_operation_opportunity if last_financed_on.blank? && recent_sii_activity?

    :low_signal
  end

  def calculated_next_best_action
    return :review_risk if risk_eligibilities.company_level.order(evaluated_at: :desc).first&.not_eligible?
    return :reactivate if reactivation_opportunity?
    return :first_operation if first_operation_opportunity?
    return :expand_wallet_share if share_of_wallet < 35

    :maintain_cadence
  end

  def operated_recently?(days: 30)
    last_financed_on.present? && last_financed_on >= days.days.ago.to_date
  end

  def recent_sii_activity?(days: 30)
    invoices.where(issue_date: days.days.ago.to_date..Date.current).exists?
  end
end
