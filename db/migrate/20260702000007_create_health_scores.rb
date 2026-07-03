class CreateHealthScores < ActiveRecord::Migration[7.1]
  def change
    create_table :health_scores do |t|
      t.references :company, null: false, foreign_key: true
      t.integer :score, null: false
      t.integer :churn_risk, null: false
      t.text :summary
      t.jsonb :recommended_actions, default: []

      t.timestamps
    end
  end
end
