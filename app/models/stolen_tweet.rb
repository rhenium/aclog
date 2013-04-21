class StolenTweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :original, class_name: :Tweet

  def self.register(original_tweet, the_tweet)
    begin
      create!(tweet_id: the_tweet.id, original_id: original_tweet.id)
    rescue ActiveRecord::RecordNotUnique
      logger.error("Duplicate Stolen Info")
    rescue
      logger.error("Unknown error while inserting stolen info: #{$!}/#{$@}")
    end
  end
end
