class CreateDebtors < ActiveRecord::Migration[7.1]
  def change
    create_table :debtors do |t|
      t.string :legal_name, null: false
      t.string :tax_id, null: false
      t.string :sector

      t.timestamps
    end

    add_index :debtors, :tax_id, unique: true
  end
end
