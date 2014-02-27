class Retweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  def self.create_from_json(json)
    tweet = Tweet.create_from_json(json[:retweeted_status])
    user = User.create_from_json(json[:user])

    retweet = Retweet.new(id: json[:id], tweet: tweet, user: user)

    transaction do
      retweet.save!
      tweet.update_reactions_count(retweets_count: 1, json: json[:retweeted_status])
    end
  rescue ActiveRecord::RecordNotUnique => e
    logger.debug("Duplicate retweet: #{retweet.id}: #{retweet.user_id} => #{retweet.tweet_id}")
  rescue => e
    logger.error("Failed to create a retweet: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
  ensure
    return retweet
  end

  def self.destroy_from_json(json)
    transaction do
      retweet = self.where(id: json[:delete][:status][:id]).first

      if retweet
        deleted_count = self.delete(retweet.id)
        if deleted_count > 0
          retweet.tweet.update_reactions_count(retweets_count: -1)
        end
      end
    end
  rescue => e
    logger.error("Failed to destroy a retweet: #{e.class}: #{e.message}/#{e.backtrace.join("\n")}")
  end
end
