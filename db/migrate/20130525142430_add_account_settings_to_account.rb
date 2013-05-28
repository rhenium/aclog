class AddAccountSettingsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :notification, :boolean, null: false, default: false
    add_column :accounts, :private, :boolean, null: false, default: false
    add_column :accounts, :status, :integer, limit: 2, null: false, default: 0
  end
end

