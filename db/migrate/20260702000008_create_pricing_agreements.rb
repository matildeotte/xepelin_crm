class CreatePricingAgreements < ActiveRecord::Migration[7.1]
  def change
    create_table :pricing_agreements do |t|
      t.references :company, null: false, foreign_key: true
      t.references :debtor, null: false, foreign_key: true
      t.decimal :monthly_rate, precision: 5, scale: 2, null: false
      t.decimal :approved_limit, precision: 14, scale: 2
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :pricing_agreements, [:company_id, :debtor_id], unique: true
  end
end
