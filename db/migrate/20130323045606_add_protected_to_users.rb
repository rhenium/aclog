class AddProtectedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :protected, :boolean
  end
end
