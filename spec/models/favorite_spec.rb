require 'spec_helper'

describe Favorite do
  describe ".from_hash" do
    let(:hash) { {tweet_id: 123, user_id: 456} }
    subject { Favorite.from_hash(hash) }
    its(:tweet_id) { should be 123 }
    its(:user_id) { should be 456 }
  end

  describe ".from_tweet_object" do
    let(:user) { FactoryGirl.create(:user_1) }
    let(:tweet) { FactoryGirl.create(:tweet, user: user) }
    let(:tweet_object) { OpenStruct.new(
      favoriters: [123, 456, 789, 1012, 345, 678],
      id: tweet.id) }
    subject { Favorite.from_tweet_object(tweet_object); tweet.favorites.map(&:user_id).sort }
    its(:count) { should be 6 }
    it { should eq tweet_object.favoriters.sort }
  end
end
