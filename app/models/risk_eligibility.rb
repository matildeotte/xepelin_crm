class RiskEligibility < ApplicationRecord
  belongs_to :company
  belongs_to :debtor, optional: true

  STATUSES = %w[eligible in_review not_eligible].freeze
  RISK_TYPES = %w[credit operational fraud none].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :risk_type, inclusion: { in: RISK_TYPES }
  validates :evaluated_at, presence: true

  scope :company_level, -> { where(debtor_id: nil) }
  scope :relationship_level, -> { where.not(debtor_id: nil) }

  def eligible?
    status == "eligible"
  end

  def in_review?
    status == "in_review"
  end

  def not_eligible?
    status == "not_eligible"
  end
end
