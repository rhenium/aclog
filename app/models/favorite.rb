class Favorite < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  # Registers favorite event in bulk from an array of Streaming API events.
  # This method doesn't update Tweet#reactions_count.
  #
  # @param [Array] array An array of Streaming API events.
  def self.create_bulk_from_json(array)
    objects = array.map do |json|
      self.new(user_id: json[:source][:id],
               tweet_id: json[:target_object][:id])
    end

    self.import(objects, ignore: true)
  end

  # Unregisters favorite event in bulk from an array of Streaming API 'unfavorite' events.
  # This method doesn't update Tweet#reactions_count.
  #
  # @param [Array] array An array of Streaming API events.
  def self.delete_bulk_from_json(array)
    array.each do |json|
      self.delete_all(user_id: json[:source][:id], tweet_id: json[:target_object][:id])
    end
  end
end
