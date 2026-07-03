class Interaction < ApplicationRecord
  belongs_to :company

  enum :kind, %i[email whatsapp call video_call in_person_meeting note follow_up risk_review pricing_review]

  validates :kind, :summary, presence: true
end
