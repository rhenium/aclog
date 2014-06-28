class ReorganizeAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :private, :boolean, default: false, null: false
    rename_column :accounts, :notification, :notification_enabled
    add_index :accounts, :status
  end
end
