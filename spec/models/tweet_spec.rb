# -*- coding: utf-8 -*-
require 'spec_helper'

describe Tweet do
  before do
    @user_0, @user_1, @user_2 = FactoryGirl.create_list(:user, 3) # t/f/r = 3/1/0, 1/2/1, 0/0/1

    @tweet_0_0 = FactoryGirl.create(:tweet, user: @user_0, tweeted_at: 2.days.ago) # f/r = 2/0
    @tweet_0_1 = FactoryGirl.create(:tweet, user: @user_0, tweeted_at: 4.days.ago) # f/r = 0/1
    @tweet_0_2 = FactoryGirl.create(:tweet, user: @user_0, tweeted_at: 6.days.ago) # f/r = 0/0
    @tweet_1_0 = FactoryGirl.create(:tweet, user: @user_1, tweeted_at: 1.days.ago) # f/r = 1/1

    @tweet_0_0_f_0 = FactoryGirl.create(:favorite, user: @user_0, tweet: @tweet_0_0)
    @tweet_0_0_f_1 = FactoryGirl.create(:favorite, user: @user_1, tweet: @tweet_0_0)
    @tweet_0_1_r_1 = FactoryGirl.create(:retweet,  user: @user_1, tweet: @tweet_0_1)
    @tweet_1_0_f_1 = FactoryGirl.create(:favorite, user: @user_1, tweet: @tweet_1_0)
    @tweet_1_0_r_2 = FactoryGirl.create(:retweet,  user: @user_2, tweet: @tweet_1_0)
  end

  describe ".create!" do
    subject { @tweet_0_0 }
    its(:text) { should_not be nil }
    its(:source) { should_not be nil }
    its(:user_id) { should be @user_0.id }
    its(:user) { should eq @user_0 }
  end

  describe "counter_cache" do
    subject { @tweet_0_0.reload }
    its(:favorites_count) { should be subject.favorites.count }
    its(:retweets_count) { should be subject.retweets.count }
  end

  describe ".delete_from_id" do
    context "when of tweet" do
      subject { Tweet.delete_from_id(@tweet_1_0.id) }
      it { should be @tweet_1_0.id }
      it { Tweet.where(id: subject).first.should be nil }
      it { Favorite.where(tweet_id: subject).count.should be 0 }
      it { Retweet.where(tweet_id: subject).count.should be 0 }
    end

    context "when of retweet" do
      subject { Tweet.delete_from_id(@tweet_1_0_r_2.id).tap { @tweet_1_0.reload } }
      it { should be @tweet_1_0_r_2.id }
      it { Retweet.where(id: subject).first.should be nil }
      it { @tweet_1_0.retweets_count.should be 0 }
    end
  end

  describe ".from_hash" do
    let(:test_data) do
      {text: "abc",
       source: "web",
       tweeted_at: Time.now,
       user_id: @user_0.id}
    end

    subject { Tweet.from_hash(test_data) }
    it { should be_a Tweet }
    its(:text) { should eq test_data[:text] }
    its(:source) { should eq test_data[:source] }
    its(:tweeted_at) { should eq test_data[:tweeted_at] }
    its(:user) { should eq @user_0 }
  end

  context "scopes" do
    describe "recent" do
      subject { Tweet.recent }
      it { should_not include -> tweet { tweet.tweeted_at < Time.zone.now - 3.days } }
      its(:count) { should be 2 }
    end

    describe "reacted" do
      subject { Tweet.reacted }
      it { should_not include -> tweet { tweet.favorites_count + tweet.retweets_count == 0 } }
      it { should_not include -> tweet { tweet.favorites.count + tweet.retweets.count == 0 } }
      its(:count) { should be 3 }
    end

    describe "order_by_id" do
      subject { Tweet.order_by_id }
      it { subject.first.id.should be > subject.last.id }
    end

    describe "order_by_favorites" do
      subject { Tweet.order_by_favorites }
      it { subject.first.favorites.count.should be >= subject.last.favorites.count }
    end

    describe "order_by_retweets" do
      subject { Tweet.order_by_retweets }
      it { subject.first.retweets.count.should be >= subject.last.retweets.count }
    end

    describe "order_by_reactions" do
      subject { Tweet.order_by_favorites }
      it {
        (subject.first.favorites.count + subject.first.retweets.count)
           .should be >= (subject.last.favorites.count + subject.last.retweets.count)
      }
    end

    describe "of" do
      subject { Tweet.of(@user_1) }
      its(:to_sql) { should eq @user_1.tweets.to_sql }
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

    describe "original" do
      # TODO
    end

    describe "not_protected" do
      # TODO
    end
  end
end
