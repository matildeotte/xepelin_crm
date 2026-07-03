class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.references :user, null: false, foreign_key: true
      t.string :legal_name, null: false
      t.string :tax_id, null: false
      t.string :sector
      t.datetime :sii_connected_at
      t.text :notes

      t.timestamps
    end

    add_index :companies, :tax_id, unique: true
  end
end
