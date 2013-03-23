class AddUserIdIndexToEvents < ActiveRecord::Migration
  def change
    add_index :favorites, :user_id
    add_index :retweets, :user_id
  end
end
