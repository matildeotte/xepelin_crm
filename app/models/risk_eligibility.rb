class RiskEligibility < ApplicationRecord
  belongs_to :company
  belongs_to :debtor, optional: true

  after_commit :refresh_company_commercial_state

  enum :status, %i[eligible in_review not_eligible]
  enum :risk_type, %i[credit operational fraud none], prefix: :risk_type

  validates :status, inclusion: { in: statuses.keys }
  validates :risk_type, inclusion: { in: risk_types.keys }
  validates :evaluated_at, presence: true

  scope :company_level, -> { where(debtor_id: nil) }
  scope :relationship_level, -> { where.not(debtor_id: nil) }

  private

  def refresh_company_commercial_state
    company.refresh_commercial_state! if company&.persisted? && !company.destroyed?
  end
end
