class AddReactionsCountToTweets < ActiveRecord::Migration
  def change
    add_column :tweets, :reactions_count, :integer, null: false, default: 0
    add_index :tweets, :reactions_count
  end
end
