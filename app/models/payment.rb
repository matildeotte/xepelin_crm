class Payment < ApplicationRecord
  belongs_to :invoice

  validates :payment_date, :amount_paid, presence: true
end
