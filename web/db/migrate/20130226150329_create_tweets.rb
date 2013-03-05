class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.text :text
      t.text :source
      t.references :user, :limit => 8
      t.datetime :tweeted_at

      t.integer :favorites_count
      t.integer :retweets_count
    end
  end
end
