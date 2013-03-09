class Favorite < ActiveRecord::Base
#  attr_accessible :tweet, :user
  belongs_to :tweet, :counter_cache => true
  belongs_to :user
end
