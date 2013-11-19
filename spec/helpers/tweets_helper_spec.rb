# -*- encoding: utf-8 -*-
require "spec_helper"

describe TweetsHelper do
  describe "#favorites_truncate_count" do
    subject { helper.favorites_truncate_count }

    context "when full=tree" do
      before { params[:full] = "true" }
      it { should eq nil }
    end

    context "when full!=true" do
      it { should eq Settings.tweets.favorites.truncate }
    end
  end

  describe "#favorites_truncated?" do
    let(:user) { FactoryGirl.create(:user) }
    subject { helper.favorites_truncated?(tweet) }
    context "when full=true" do
      before { helper.stub(:favorites_truncate_count).and_return(nil) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.favorites.truncate + 1, retweets_count: Settings.tweets.favorites.truncate + 1) }
      it { should be false }
    end
    context "when _count equals count_default" do
      before { helper.stub(:favorites_truncate_count).and_return(Settings.tweets.favorites.truncate) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.favorites.truncate, retweets_count: Settings.tweets.favorites.truncate) }
      it { should be false }
    end
    context "when _count is larger than count_default" do
      before { helper.stub(:favorites_truncate_count).and_return(Settings.tweets.favorites.truncate) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.favorites.truncate + 1, retweets_count: Settings.tweets.favorites.truncate + 1) }
      it { should be true }
    end
  end
end

