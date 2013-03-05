class User < ActiveRecord::Base
#  attr_accessible :id, :screen_name, :name, :profile_image_url
  has_many :tweets, :dependent => :delete_all
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all
end
