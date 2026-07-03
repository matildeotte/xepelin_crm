class PricingAgreement < ApplicationRecord
  belongs_to :company
  belongs_to :debtor

  validates :monthly_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :company_id, uniqueness: { scope: :debtor_id }
end
