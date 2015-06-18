class Favorite < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  class << self
    # Registers favorite event in bulk from an array of Streaming API events.
    # This method doesn't update Tweet#reactions_count.
    #
    # @param [Array] array An array of Streaming API events.
    def create_bulk_from_json(array)
      return if array.empty?

      keys = [:user_id, :tweet_id]
      objects = array.map {|json|
        [json[:source][:id], json[:target_object][:id]]
      }

      import(keys, objects, ignore: true)
    end

    # Unregisters favorite event in bulk from an array of Streaming API 'unfavorite' events.
    # This method doesn't update Tweet#reactions_count.
    #
    # @param [Array] array An array of Streaming API events.
    def delete_bulk_from_json(array)
      array.each do |json|
        delete_all(user_id: json[:source][:id],
                   tweet_id: json[:target_object][:id])
      end
    end
  end
end
