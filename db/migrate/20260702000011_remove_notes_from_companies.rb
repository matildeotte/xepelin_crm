class RemoveNotesFromCompanies < ActiveRecord::Migration[7.1]
  def change
    remove_column :companies, :notes, :text
  end
end
