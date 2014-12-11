class Retweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  # Registers retweet event in bulk from an array of Streaming API messages.
  # This doesn't update Tweet#reactions_count.
  #
  # @param [Array] array An array of Streaming API messages.
  def self.create_bulk_from_json(array)
    return if array.empty?

    objects = array.map do |json|
      {
        id: json[:id],
        user_id: json[:user][:id],
        tweet_id: json[:retweeted_status][:id]
      }
    end

    self.import(objects.first.keys, objects.map(&:values), ignore: true)
  end

  # Unregisters retweet events in bulk from array of Streaming API's delete events.
  # This doesn't update Tweet#reactions_count.
  #
  # @param [Array] array An array of Streaming API delete events.
  def self.delete_bulk_from_json(array)
    self.where(id: array.map {|json| json[:delete][:status][:id] }).delete_all
  end
end
