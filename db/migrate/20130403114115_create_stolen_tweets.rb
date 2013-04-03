class CreateStolenTweets < ActiveRecord::Migration
  def change
    create_table :stolen_tweets do |t|
      t.integer :tweet_id, :limit => 8
      t.integer :original_id, :limit => 8
    end

    add_index :stolen_tweets, :tweet_id, :unique => true
    add_index :stolen_tweets, :original_id
  end
end
