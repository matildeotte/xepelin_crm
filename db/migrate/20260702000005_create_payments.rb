class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.date :payment_date, null: false
      t.decimal :amount_paid, precision: 14, scale: 2, null: false

      t.timestamps
    end
  end
end
