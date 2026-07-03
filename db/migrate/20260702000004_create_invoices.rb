class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.references :company, null: false, foreign_key: true
      t.references :debtor, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false
      t.date :issue_date, null: false
      t.date :due_date, null: false
      t.date :financed_on
      t.string :source, default: "sii_only", null: false
      t.string :status, default: "pending", null: false
      t.boolean :assigned, default: false, null: false
      t.date :assignment_date
      t.string :debtor_response_status, default: "pending", null: false
      t.string :rejection_reason
      t.decimal :moratory_monthly_rate, precision: 5, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :invoices, :invoice_number
    add_index :invoices, [:company_id, :source]
    add_index :invoices, [:company_id, :status]
    add_index :invoices, [:debtor_id, :source]
    add_index :invoices, :due_date
    add_index :invoices, :financed_on
  end
end
