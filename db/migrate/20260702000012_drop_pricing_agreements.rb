class DropPricingAgreements < ActiveRecord::Migration[7.1]
  def change
    drop_table :pricing_agreements, if_exists: true do |t|
      t.references :company, null: false, foreign_key: true
      t.references :debtor, null: false, foreign_key: true
      t.decimal :monthly_rate, precision: 5, scale: 2, null: false
      t.decimal :approved_limit, precision: 14, scale: 2
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
