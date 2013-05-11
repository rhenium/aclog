require 'spec_helper'

describe Retweet do
  describe ".from_hash" do
    let(:hash) { {id: 890, tweet_id: 123, user_id: 456} }
    subject { Retweet.from_hash(hash) }
    its(:id) { should be 890 }
    its(:tweet_id) { should be 123 }
    its(:user_id) { should be 456 }
  end

  describe ".from_tweet_object" do
    let(:user) { FactoryGirl.create(:user_1) }
    let(:tweet) { FactoryGirl.create(:tweet, user: user) }
    let(:tweet_object) { OpenStruct.new(
      user: OpenStruct.new(user.attributes.update(profile_image_url_https: "abc")),
      id: 890,
      user_id: 123,
      retweeted_status: OpenStruct.new(id: tweet.id)) }
    subject { Retweet.from_tweet_object(tweet_object); tweet.retweets.map(&:user_id).sort }
    its(:count) { should be 1 }
    it { should eq [user.id] }
  end
end
