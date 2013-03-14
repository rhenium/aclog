class User < ActiveRecord::Base
  has_many :tweets, :dependent => :delete_all
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all
end
