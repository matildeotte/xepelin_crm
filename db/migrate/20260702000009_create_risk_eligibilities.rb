class CreateRiskEligibilities < ActiveRecord::Migration[7.1]
  def change
    create_table :risk_eligibilities do |t|
      t.references :company, null: false, foreign_key: true
      t.references :debtor, null: true, foreign_key: true
      t.string :status, null: false
      t.string :risk_type, default: "none", null: false
      t.text :reason
      t.datetime :evaluated_at, null: false

      t.timestamps
    end

    add_index :risk_eligibilities, [:company_id, :debtor_id]
    add_index :risk_eligibilities, :status
  end
end
