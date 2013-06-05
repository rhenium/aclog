# -*- encoding: utf-8 -*-
require "spec_helper"

describe TweetsHelper do
  describe "#user_limit" do
    subject { helper.user_limit }

    context "when timeline and format is HTML" do
      before { controller.request.format = :html }
      it { should eq Settings.tweets.users.count_default }
    end

    context "when tweet and format is HTML" do
      before do
        controller.request.format = :html
        params[:action] = "show"
      end
      it { should eq Settings.tweets.users.count_lot }
    end

    context "when tweet and format is HTML with full=true parameter" do
      before do
        controller.request.format = :html
        params[:action] = "show"
        params[:full] = "true"
      end
      it { should be nil }
    end

    context "when JSON" do
      before { controller.request.format = :json }
      it { should be nil }
    end

    context "when JSON with `limit` parameter" do
      let(:limit) { "123" }
      before do
        controller.request.format = :json
        params[:limit] = limit
      end
      it { should eq limit.to_i }
    end
  end

  describe "#user_truncated?" do
    let(:user) { FactoryGirl.create(:user) }
    subject { helper.user_truncated?(tweet) }
    context "when full=true" do
      before { helper.stub!(:user_limit).and_return(nil) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.users.count_lot + 1, retweets_count: Settings.tweets.users.count_lot + 1) }
      it { should be false }
    end
    context "when _count equals count_default" do
      before { helper.stub!(:user_limit).and_return(Settings.tweets.users.count_default) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.users.count_default, retweets_count: Settings.tweets.users.count_default) }
      it { should be false }
    end
    context "when _count is larger than count_default" do
      before { helper.stub!(:user_limit).and_return(Settings.tweets.users.count_default) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.users.count_default, retweets_count: Settings.tweets.users.count_default + 1) }
      it { should be true }
    end
  end
end

