class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :debtor
  has_many :payments, dependent: :destroy

  after_commit :refresh_company_commercial_state

  enum :source, %i[xepelin sii_only]
  enum :status, %i[pending paid overdue]
  enum :debtor_response_status, %i[pending accepted rejected], prefix: :debtor_response

  validates :invoice_number, :amount, :issue_date, :due_date, :source, :status, presence: true
  validates :source, inclusion: { in: sources.keys }
  validates :status, inclusion: { in: statuses.keys }
  validates :debtor_response_status, inclusion: { in: debtor_response_statuses.keys }

  scope :unpaid, -> { where(status: statuses.values_at("pending", "overdue")) }
  scope :due_soon, ->(days = 7) { pending.where(due_date: Date.current..(Date.current + days.days)) }

  def financed?
    xepelin?
  end

  def paid_on
    payments.maximum(:payment_date)
  end

  def paid_on_time?
    paid? && paid_on.present? && paid_on <= due_date
  end

  def days_overdue
    return 0 unless overdue?

    (Date.current - due_date).to_i
  end

  def collection_blocker?
    financed? && overdue?
  end

  private

  def refresh_company_commercial_state
    company.refresh_commercial_state! if company&.persisted? && !company.destroyed?
  end
end
