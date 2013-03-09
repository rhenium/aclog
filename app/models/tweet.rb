class Tweet < ActiveRecord::Base
#  attr_accessible :id, :text, :source, :tweeted_at, :user
  belongs_to :user
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all
end
