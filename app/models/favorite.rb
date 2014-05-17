class Favorite < ActiveRecord::Base
  belongs_to :tweet
  belongs_to :user

  # This doesn't update Tweet#reactions_count.
  def self.create_bulk_from_json(array)
    objects = array.map do |json|
      self.new(user_id: json[:source][:id],
               tweet_id: json[:target_object][:id])
    end

    self.import(objects, ignore: true)
  end

  # This doesn't update Tweet#reactions_count.
  def self.delete_bulk_from_json(array)
    array.each do |json|
      self.delete_all(user_id: json[:source][:id], tweet_id: json[:target_object][:id])
    end
  end
end
