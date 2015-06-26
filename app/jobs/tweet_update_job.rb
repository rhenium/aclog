class TweetUpdateJob < ActiveJob::Base
  queue_as :low_priority

  def perform(id_or_ids)
    ids = id_or_ids.is_a?(Array) ? id_or_ids : [id_or_ids]

    ids.each do |id|
      Tweet.update_from_twitter(id)
    end
  end
end
