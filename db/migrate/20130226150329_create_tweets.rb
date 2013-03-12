class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.text :text, :null => false
      t.text :source
      t.references :user, :limit => 8, :null => false
      t.datetime :tweeted_at

      t.integer :favorites_count, :default => 0
      t.integer :retweets_count, :default => 0
    end

    add_index :tweets, :user_id
  end
end
