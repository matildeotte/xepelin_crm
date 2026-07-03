class HealthScore < ApplicationRecord
  belongs_to :company

  enum :churn_risk, %i[low medium high]

  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
