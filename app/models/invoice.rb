class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :debtor
  has_many :payments, dependent: :destroy

  SOURCES = %w[xepelin sii_only].freeze
  STATUSES = %w[pending paid overdue].freeze
  DEBTOR_RESPONSE_STATUSES = %w[pending accepted rejected].freeze

  validates :invoice_number, :amount, :issue_date, :due_date, :source, :status, presence: true
  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }
  validates :debtor_response_status, inclusion: { in: DEBTOR_RESPONSE_STATUSES }

  scope :xepelin, -> { where(source: "xepelin") }
  scope :sii_only, -> { where(source: "sii_only") }
  scope :unpaid, -> { where(status: %w[pending overdue]) }
  scope :overdue, -> { where(status: "overdue") }
  scope :due_soon, ->(days = 7) { where(status: "pending", due_date: Date.current..(Date.current + days.days)) }

  def financed?
    source == "xepelin"
  end

  def paid?
    status == "paid"
  end

  def pending?
    status == "pending"
  end

  def overdue?
    status == "overdue"
  end

  def paid_on
    payments.maximum(:payment_date)
  end

  def paid_on_time?
    status == "paid" && paid_on.present? && paid_on <= due_date
  end

  def days_overdue
    return 0 unless overdue?

    (Date.current - due_date).to_i
  end

  def collection_blocker?
    financed? && overdue?
  end
end
