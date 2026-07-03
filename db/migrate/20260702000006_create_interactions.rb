class CreateInteractions < ActiveRecord::Migration[7.1]
  def change
    create_table :interactions do |t|
      t.references :company, null: false, foreign_key: true
      t.integer :kind, null: false
      t.text :summary, null: false

      t.timestamps
    end
  end
end
