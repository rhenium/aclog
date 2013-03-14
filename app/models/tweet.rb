class Tweet < ActiveRecord::Base
  belongs_to :user
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all
end
