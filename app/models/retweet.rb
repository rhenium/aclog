class Retweet < ActiveRecord::Base
#  attr_accessible :id, :tweet, :user
  belongs_to :tweet, :counter_cache => true
  belongs_to :user
end
