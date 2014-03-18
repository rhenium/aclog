class Retweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  def self.create_from_json(json)
    tweet = Tweet.create_from_json(json[:retweeted_status])
    user = User.create_from_json(json[:user])

    transaction do
      retweet = Retweet.create!(id: json[:id], tweet: tweet, user: user)
      tweet.update_reactions_count(retweets_count: 1, json: json[:retweeted_status])

      retweet
    end
  rescue ActiveRecord::RecordNotUnique => e
    logger.debug("Duplicate retweet: #{json[:id]}: #{user.id} => #{tweet.id}")
    self.find(json[:id])
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
  end
end
