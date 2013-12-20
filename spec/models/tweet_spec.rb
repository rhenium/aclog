# -*- coding: utf-8 -*-
require "spec_helper"

describe Tweet do
  before do
    @user_0, @user_1, @user_2 = FactoryGirl.create_list(:user, 3) # t/f/r = 3/1/0, 1/2/1, 0/0/1

    @tweet_0_0 = FactoryGirl.create(:tweet, id: snowflake_min(2.days.ago) + 5000, user: @user_0, tweeted_at: 2.days.ago) # f/r = 2/0
    @tweet_0_1 = FactoryGirl.create(:tweet, id: snowflake_min(4.days.ago) + 5000, user: @user_0, tweeted_at: 4.days.ago) # f/r = 0/1
    @tweet_0_2 = FactoryGirl.create(:tweet, id: snowflake_min(6.days.ago) + 5000, user: @user_0, tweeted_at: 6.days.ago) # f/r = 0/0
    @tweet_1_0 = FactoryGirl.create(:tweet, id: snowflake_min(1.days.ago) + 5000, user: @user_1, tweeted_at: 1.days.ago) # f/r = 1/1

    @tweet_0_0_f_0 = FactoryGirl.create(:favorite, user: @user_0, tweet: @tweet_0_0)
    @tweet_0_0_f_1 = FactoryGirl.create(:favorite, user: @user_1, tweet: @tweet_0_0)
    @tweet_0_1_r_1 = FactoryGirl.create(:retweet,  user: @user_1, tweet: @tweet_0_1)
    @tweet_1_0_f_1 = FactoryGirl.create(:favorite, user: @user_1, tweet: @tweet_1_0)
    @tweet_1_0_r_2 = FactoryGirl.create(:retweet,  user: @user_2, tweet: @tweet_1_0)
  end

  describe "counter_cache" do
    subject { @tweet_0_0.reload }
    its(:favorites_count) { should be subject.favorites.count }
    its(:retweets_count) { should be subject.retweets.count }
    its(:reactions_count) { should be subject.favorites.count + subject.retweets.count }
  end

  describe "#twitter_url" do
    subject { @tweet_0_0.twitter_url }
    it { should eq "https://twitter.com/#{@tweet_0_0.user.screen_name}/status/#{@tweet_0_0.id}" }
  end

  describe ".delete_from_id" do
    context "when of tweet" do
      before do
        @id = @tweet_1_0.id
        @result = OpenStruct.new(Tweet.delete_from_id(@id))
      end
      it { @result.tweets.should be 1 }
      it { @result.favorites.should be 1 }
      it { @result.retweets.should be 1 }
      it { Tweet.find_by(id: @id).should be nil }
      it { Favorite.where(tweet_id: @id).count.should be 0 }
      it { Retweet.where(tweet_id: @id).count.should be 0 }
    end

    context "when of retweet" do
      before do
        @id = @tweet_1_0_r_2.id
        @result = OpenStruct.new(Tweet.delete_from_id(@id))
      end
      it { @result.tweets.should be 0 }
      it { @result.retweets.should be 1 }
      it { Tweet.find_by(id: @tweet_1_0).retweets_count.should be 0 }
      it { Favorite.where(tweet_id: @id).count.should be 0 }
      it { Retweet.where(id: @id).count.should be 0 }
    end
  end

  describe ".from_receiver" do
    let(:test_data) do
      {"id" => 123,
       "text" => "abc",
       "entities" => {},
       "source" => "web",
       "created_at" => Time.now.to_s,
       "user" => {"id" => @user_0.id}}
    end

    subject { Tweet.from_receiver(test_data) }
    it { should be_a Tweet }
    its(:id) { should be test_data["id"] }
    its(:text) { should eq test_data["text"] }
    its(:source) { should eq test_data["source"] }
    its(:tweeted_at) { should eq Time.parse(test_data["created_at"]) }
    its(:user) { should eq @user_0 }
  end

  context "scopes" do
    describe "recent" do
      subject { Tweet.recent(3) }
      it { should_not include -> tweet { tweet.tweeted_at < Time.now - 3.days } }
      its(:count) { should be 2 }
    end

    describe "reacted" do
      subject { Tweet.reacted }
      it { should_not include -> tweet { tweet.favorites_count + tweet.retweets_count == 0 } }
      its(:count) { should be 3 }
    end

    describe "not_protected" do
      subject { Tweet.not_protected.includes(:user) }
      it { should_not include -> tweet { tweet.user.protected? } }
    end

    describe "max_id" do
      subject { Tweet.max_id(@tweet_0_0.id - 1) }
      its(:count) { should be 2 }
      it { should_not include -> tweet { tweet.id > @tweet_0_0.id - 1 } }
    end

    describe "since_id" do
      subject { Tweet.since_id(@tweet_0_0.id) }
      its(:count) { should be 1 }
      it { should_not include -> tweet { tweet.id <= @tweet_0_0.id } }
    end

    describe "page" do
      subject { Tweet.limit(3).page(2) }
      its(:count) { should be 1 }
    end

    describe "order_by_id" do
      subject { Tweet.order_by_id }
      it { subject.first.id.should be > subject.last.id }
    end

    describe "order_by_reactions" do
      subject { Tweet.order_by_reactions }
      it {
        (subject.first.favorites.count + subject.first.retweets.count)
           .should be >= (subject.last.favorites.count + subject.last.retweets.count)
      }
    end

    describe "favorited_by" do
      subject { Tweet.favorited_by(@user_1) }
      its(:count) { should be 2 }
      it { should_not include -> tweet { not tweet.favorites.any? {|a| a.user_id == @user_1.id } } }
    end

    describe "retweeted_by" do
      subject { Tweet.retweeted_by(@user_2) }
      its(:count) { should be 1 }
      it { should_not include -> tweet { not tweet.retweets.any? {|a| a.user_id == @user_2.id } } }
    end

    describe "discovered_by" do
      subject { Tweet.discovered_by(@user_1) }
      its(:count) { should be 3 }
      it { subject.select {|m| m.favorites.any? {|n| n.user_id == @user_1.id } }.count.should be 2 }
      it { subject.select {|m| m.retweets.any? {|n| n.user_id == @user_1.id } }.count.should be 1 }
      it { should_not include -> tweet { not (tweet.retweets + tweet.favorites).any? {|a| a.user_id == @user_1.id } } }
    end
  end
end
