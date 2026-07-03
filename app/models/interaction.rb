class Interaction < ApplicationRecord
  belongs_to :company

  validates :kind, :summary, presence: true
end
