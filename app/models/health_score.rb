class HealthScore < ApplicationRecord
  belongs_to :company

  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :churn_risk, inclusion: { in: %w[low medium high] }
  validates :generated_at, presence: true
end
