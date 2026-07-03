Payment.destroy_all
RiskEligibility.destroy_all
HealthScore.destroy_all
Interaction.destroy_all
Invoice.destroy_all
Debtor.destroy_all
Company.destroy_all
User.destroy_all

def tax_id(sequence)
  body = (76_000_000 + sequence).to_s
  "#{body}-#{sequence % 10}"
end

demo_email = ENV.fetch("DEMO_USER_EMAIL", "kam.demo@xepelin.com")

primary_kam = User.create!(
  email: demo_email,
  name: "Demo KAM",
  google_uid: "demo-google-uid",
  avatar_url: nil
)

secondary_kam = User.create!(
  email: "other.kam@xepelin.com",
  name: "Other KAM",
  google_uid: "other-google-uid",
  avatar_url: nil
)

sectors = ["Alimentos", "Construcción", "Logística", "Retail", "Salud", "Manufactura", "Tecnología"]

debtors = 12.times.map do |index|
  Debtor.create!(
    legal_name: "#{Faker::Company.name} SpA",
    tax_id: tax_id(index + 100),
    sector: sectors.sample
  )
end

profiles = [
  :operating_high_sow,
  :operating_low_sow,
  :reactivation,
  :first_operation,
  :collection_blocker,
  :operating_low_sow,
  :reactivation,
  :operating_high_sow,
  :first_operation,
  :collection_blocker
]

companies = profiles.each_with_index.map do |profile, index|
  company = Company.create!(
    user: primary_kam,
    legal_name: "#{Faker::Company.name} Ltda",
    tax_id: tax_id(index + 1),
    sector: sectors.sample,
    sii_connected_at: rand(20..500).days.ago
  )

  company_debtors = debtors.sample(3)

  RiskEligibility.create!(
    company: company,
    status: ["eligible", "eligible", "eligible", "in_review", "not_eligible"].sample,
    risk_type: ["none", "none", "credit", "operational"].sample,
    reason: "Resultado de riesgos a nivel empresa para planificación comercial.",
    evaluated_at: rand(1..12).days.ago
  )

  company_debtors.each do |debtor|
    RiskEligibility.create!(
      company: company,
      debtor: debtor,
      status: ["eligible", "eligible", "eligible", "in_review", "not_eligible"].sample,
      risk_type: ["none", "none", "credit", "fraud", "operational"].sample,
      reason: "Elegibilidad a nivel relación entregada por el equipo de riesgos.",
      evaluated_at: rand(1..12).days.ago
    )
  end

  monthly_visible_count =
    case profile
    when :operating_high_sow then 7
    when :operating_low_sow then 10
    when :reactivation then 8
    when :first_operation then 6
    when :collection_blocker then 7
    end

  monthly_financed_count =
    case profile
    when :operating_high_sow then 5
    when :operating_low_sow then 2
    when :reactivation then 0
    when :first_operation then 0
    when :collection_blocker then 4
    end

  monthly_visible_count.times do |invoice_index|
    debtor = company_debtors.sample
    source = invoice_index < monthly_financed_count ? "xepelin" : "sii_only"
    issue_date = rand(0..24).days.ago.to_date
    due_date = issue_date + rand(20..60).days
    status = "pending"

    if source == "xepelin" && profile == :collection_blocker && invoice_index.zero?
      issue_date = 75.days.ago.to_date
      due_date = 35.days.ago.to_date
      status = "overdue"
    elsif source == "xepelin" && rand < 0.35
      status = "paid"
    end

    invoice = Invoice.create!(
      company: company,
      debtor: debtor,
      invoice_number: "F#{company.id}-#{invoice_index + 1}",
      amount: rand(3_000_000..28_000_000),
      issue_date: issue_date,
      due_date: due_date,
      financed_on: source == "xepelin" ? issue_date + rand(1..4).days : nil,
      source: source,
      status: status,
      assigned: source == "xepelin",
      assignment_date: source == "xepelin" ? issue_date + 1.day : nil,
      debtor_response_status: ["accepted", "accepted", "pending"].sample,
      moratory_monthly_rate: rand(1.0..2.8).round(2)
    )

    if invoice.status == "paid"
      Payment.create!(
        invoice: invoice,
        payment_date: invoice.due_date + rand(-5..8).days,
        amount_paid: invoice.amount
      )
    end
  end

  if profile == :reactivation
    2.times do |old_index|
      debtor = company_debtors.sample
      old_issue_date = rand(70..130).days.ago.to_date
      old_due_date = old_issue_date + rand(25..50).days

      invoice = Invoice.create!(
        company: company,
        debtor: debtor,
        invoice_number: "R#{company.id}-#{old_index + 1}",
        amount: rand(4_000_000..22_000_000),
        issue_date: old_issue_date,
        due_date: old_due_date,
        financed_on: old_issue_date + 2.days,
        source: "xepelin",
        status: "paid",
        assigned: true,
        assignment_date: old_issue_date + 1.day,
        debtor_response_status: "accepted",
        moratory_monthly_rate: rand(1.0..2.8).round(2)
      )

      Payment.create!(
        invoice: invoice,
        payment_date: old_due_date - rand(0..4).days,
        amount_paid: invoice.amount
      )
    end
  end

  Interaction.create!(
    company: company,
    kind: Interaction.kinds.keys.sample,
    summary: "Se conversó el plan operativo mensual y posibles facturas a financiar.",
    created_at: rand(1..20).days.ago
  )

  company
end

3.times do |index|
  company = Company.create!(
    user: secondary_kam,
    legal_name: "#{Faker::Company.name} SpA",
    tax_id: tax_id(index + 50),
    sector: sectors.sample,
    sii_connected_at: rand(50..400).days.ago
  )

  debtor = debtors.sample

  invoice = Invoice.create!(
    company: company,
    debtor: debtor,
    invoice_number: "G#{company.id}-1",
    amount: rand(5_000_000..30_000_000),
    issue_date: rand(10..40).days.ago.to_date,
    due_date: rand(5..30).days.from_now.to_date,
    financed_on: rand(8..35).days.ago.to_date,
    source: "xepelin",
    status: "pending",
    assigned: true,
    assignment_date: rand(8..35).days.ago.to_date,
    debtor_response_status: "accepted",
    moratory_monthly_rate: rand(1.0..2.5).round(2)
  )
end

puts "Seeded #{User.count} users, #{Company.count} companies, #{Debtor.count} debtors, #{Invoice.count} invoices."
puts "Use DEMO_USER_EMAIL=your_google_email@example.com rails db:seed to assign the demo portfolio to your Google account."
