class Retweet < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  # This doesn't update Tweet#reactions_count.
  def self.create_bulk_from_json(array)
    objects = array.map do |json|
      self.new(id: json[:id],
               user_id: json[:user][:id],
               tweet_id: json[:retweeted_status][:id])
    end

    self.import objects
  end

  # This doesn't update Tweet#reactions_count.
  def self.delete_bulk_from_json(array)
    self.where(id: array.map {|json| json[:delete][:status][:id] }).delete_all
  end
end
