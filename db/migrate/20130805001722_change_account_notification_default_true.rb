class ChangeAccountNotificationDefaultTrue < ActiveRecord::Migration
  def change
    change_column :accounts, :notification, :boolean, default: true
  end
end
