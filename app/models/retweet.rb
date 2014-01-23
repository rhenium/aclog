class Retweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  after_create do
    Tweet.update_counters(self.tweet_id, retweets_count: 1, reactions_count: 1)
  end

  after_destroy do
    Tweet.update_counters(self.tweet_id, retweets_count: -1, reactions_count: -1)
  end

  def self.from_json(json)
    tweet = Tweet.from_json(json[:retweeted_status])
    user = User.from_json(json[:user])
    retweet = Retweet.new(id: json[:id], tweet: tweet, user: user)
    if retweet.save
      logger.debug("Successfully created a retweet: #{retweet.id}")
    else
      logger.debug("Failed to create a retweet: #{retweet}")
    end

    retweet
  end
end
