class ChangeIdsToUnsigned < ActiveRecord::Migration
  def up
    # accounts
    execute "ALTER TABLE accounts " +
      "MODIFY user_id bigint unsigned NOT NULL"

    # tweets
    execute "ALTER TABLE tweets " +
      "MODIFY user_id bigint unsigned NOT NULL, " +
      "MODIFY in_reply_to_id bigint unsigned DEFAULT NULL"

    # favorites
    execute "ALTER TABLE favorites " +
      "MODIFY user_id bigint unsigned NOT NULL, " +
      "MODIFY tweet_id bigint unsigned NOT NULL"

    # retweets
    execute "ALTER TABLE retweets " +
      "MODIFY user_id bigint unsigned NOT NULL, " +
      "MODIFY tweet_id bigint unsigned NOT NULL"
  end

  def down
    # accounts
    execute "ALTER TABLE accounts " +
      "MODIFY user_id bigint NOT NULL"

    # tweets
    execute "ALTER TABLE tweets " +
      "MODIFY user_id bigint NOT NULL, " +
      "MODIFY in_reply_to_id bigint DEFAULT NULL"

    # favorites
    execute "ALTER TABLE favorites " +
      "MODIFY user_id bigint NOT NULL, " +
      "MODIFY tweet_id bigint NOT NULL"

    # retweets
    execute "ALTER TABLE retweets " +
      "MODIFY user_id bigint NOT NULL, " +
      "MODIFY tweet_id bigint NOT NULL"
  end
end
