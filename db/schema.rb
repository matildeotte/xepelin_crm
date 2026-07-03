# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_07_02_000009) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "companies", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "legal_name", null: false
    t.string "tax_id", null: false
    t.string "sector"
    t.date "onboarded_on"
    t.datetime "sii_connected_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_id"], name: "index_companies_on_tax_id", unique: true
    t.index ["user_id"], name: "index_companies_on_user_id"
  end

  create_table "debtors", force: :cascade do |t|
    t.string "legal_name", null: false
    t.string "tax_id", null: false
    t.string "sector"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_id"], name: "index_debtors_on_tax_id", unique: true
  end

  create_table "health_scores", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.integer "score", null: false
    t.string "churn_risk", null: false
    t.text "summary"
    t.jsonb "recommended_actions", default: []
    t.datetime "generated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_health_scores_on_company_id"
  end

  create_table "interactions", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "kind", null: false
    t.text "summary", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_interactions_on_company_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "debtor_id", null: false
    t.string "invoice_number", null: false
    t.decimal "amount", precision: 14, scale: 2, null: false
    t.date "issue_date", null: false
    t.date "due_date", null: false
    t.date "financed_on"
    t.string "source", default: "sii_only", null: false
    t.string "status", default: "pending", null: false
    t.boolean "assigned", default: false, null: false
    t.date "assignment_date"
    t.string "debtor_response_status", default: "pending", null: false
    t.string "rejection_reason"
    t.decimal "moratory_monthly_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "source"], name: "index_invoices_on_company_id_and_source"
    t.index ["company_id", "status"], name: "index_invoices_on_company_id_and_status"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["debtor_id", "source"], name: "index_invoices_on_debtor_id_and_source"
    t.index ["debtor_id"], name: "index_invoices_on_debtor_id"
    t.index ["due_date"], name: "index_invoices_on_due_date"
    t.index ["financed_on"], name: "index_invoices_on_financed_on"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.date "payment_date", null: false
    t.decimal "amount_paid", precision: 14, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "pricing_agreements", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "debtor_id", null: false
    t.decimal "monthly_rate", precision: 5, scale: 2, null: false
    t.decimal "approved_limit", precision: 14, scale: 2
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "debtor_id"], name: "index_pricing_agreements_on_company_id_and_debtor_id", unique: true
    t.index ["company_id"], name: "index_pricing_agreements_on_company_id"
    t.index ["debtor_id"], name: "index_pricing_agreements_on_debtor_id"
  end

  create_table "risk_eligibilities", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "debtor_id"
    t.string "status", null: false
    t.string "risk_type", default: "none", null: false
    t.text "reason"
    t.datetime "evaluated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "debtor_id"], name: "index_risk_eligibilities_on_company_id_and_debtor_id"
    t.index ["company_id"], name: "index_risk_eligibilities_on_company_id"
    t.index ["debtor_id"], name: "index_risk_eligibilities_on_debtor_id"
    t.index ["status"], name: "index_risk_eligibilities_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "google_uid", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "companies", "users"
  add_foreign_key "health_scores", "companies"
  add_foreign_key "interactions", "companies"
  add_foreign_key "invoices", "companies"
  add_foreign_key "invoices", "debtors"
  add_foreign_key "payments", "invoices"
  add_foreign_key "pricing_agreements", "companies"
  add_foreign_key "pricing_agreements", "debtors"
  add_foreign_key "risk_eligibilities", "companies"
  add_foreign_key "risk_eligibilities", "debtors"
end
