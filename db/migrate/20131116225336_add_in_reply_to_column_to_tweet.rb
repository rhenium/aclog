class AddInReplyToColumnToTweet < ActiveRecord::Migration
  def change
    add_column :tweets, :in_reply_to_id, :integer, limit: 8
    add_index :tweets, :in_reply_to_id
  end
end
