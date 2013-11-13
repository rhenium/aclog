class AddIndicesToTweets < ActiveRecord::Migration
  def change
    remove_index :tweets, :user_id
    add_index :tweets, [:user_id, :reactions_count]
  end
end
