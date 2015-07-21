class TweetUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(id_or_ids)
    Tweet.update_from_twitter(id_or_ids)
  end
end
