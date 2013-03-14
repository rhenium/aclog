class CreateRetweets < ActiveRecord::Migration
  def change
    create_table :retweets do |t|
      t.references :tweet, :limit => 8, :null => false
      t.references :user, :limit => 8, :null => false
    end

    add_index :retweets, [:tweet_id, :user_id], :unique => true
    add_index :retweets, :tweet_id
  end
end
