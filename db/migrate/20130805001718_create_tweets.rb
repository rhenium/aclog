class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.text :text,                 null: false
      t.text :source,               null: false
      t.references :user, limit: 8, null: false
      t.datetime :tweeted_at,       null: false

      t.integer :favorites_count,   null: false, default: 0
      t.integer :retweets_count,    null: false, default: 0
    end

    add_index :tweets, :user_id
  end
end
