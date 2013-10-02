class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.references :tweet,  limit: 8, null: false
      t.references :user,   limit: 8, null: false
    end

    add_index :favorites, [:tweet_id, :user_id], unique: true
    add_index :favorites, :user_id
  end
end
