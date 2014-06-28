class ReorganizeUsers < ActiveRecord::Migration
  def change
    change_column :users, :screen_name, :string, limit: 20, null: false
    change_column :users, :name, :string, limit: 64, null: false
    change_column :users, :profile_image_url, :string, null: false
    change_column :users, :protected, :boolean, null: false
    change_column :users, :updated_at, :datetime, null: false
    remove_column :users, :created_at, :datetime
  end
end
