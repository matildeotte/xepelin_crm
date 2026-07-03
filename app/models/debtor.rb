class Debtor < ApplicationRecord
  has_many :invoices, dependent: :restrict_with_error
  has_many :companies, -> { distinct }, through: :invoices
  has_many :risk_eligibilities, dependent: :destroy

  attribute :payment_probability, :integer

  enum :payment_probability, %i[no_history high medium low]

  validates :legal_name, :tax_id, presence: true
  validates :tax_id, uniqueness: true

  def invoices_for_user(user)
    invoices.joins(:company).where(companies: { user_id: user.id })
  end

  def xepelin_invoice_count
    invoices.xepelin.count
  end

  def global_financed_amount
    invoices.xepelin.sum(:amount)
  end

  def open_exposure
    invoices.xepelin.unpaid.sum(:amount)
  end

  def on_time_payment_rate
    paid = invoices.xepelin.paid.includes(:payments).to_a
    return nil if paid.empty?

    on_time = paid.count(&:paid_on_time?)
    (on_time.to_f / paid.size * 100).round(1)
  end

  def payment_probability
    rate = on_time_payment_rate
    return "no_history" if rate.nil?
    return "high" if rate >= 85
    return "medium" if rate >= 65

    "low"
  end

  def payment_probability_label
    self.class.human_enum_name(:payment_probability, payment_probability)
  end
end
