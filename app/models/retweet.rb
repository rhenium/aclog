class Retweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  class << self
    # Registers retweet event in bulk from an array of Streaming API messages.
    # This doesn't update Tweet#reactions_count.
    #
    # @param [Array] array An array of Streaming API messages.
    def create_bulk_from_json(array)
      return if array.empty?

      keys = [:id, :user_id, :tweet_id]
      objects = array.map {|json|
        [json[:id], json[:user][:id], json[:retweeted_status][:id]]
      }

      import(keys, objects, ignore: true)
    end

    # Unregisters retweet events in bulk from array of Streaming API's delete events.
    # This doesn't update Tweet#reactions_count.
    #
    # @param [Array] array An array of Streaming API delete events.
    def delete_bulk_from_json(array)
      ids = array.map {|json| json[:delete][:status][:id] }
      where(id: ids).delete_all
    end
  end
end
