class AddCommercialStateToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :activation_state, :integer, default: 3, null: false
    add_column :companies, :next_best_action, :integer, default: 4, null: false
  end
end
