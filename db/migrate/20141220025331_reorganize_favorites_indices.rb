class ReorganizeFavoritesIndices < ActiveRecord::Migration
  def change
    remove_index :favorites, [:tweet_id, :user_id]
    add_index :favorites, [:user_id, :tweet_id], unique: true
    remove_index :favorites, :user_id
    add_index :favorites, :tweet_id
  end
end
