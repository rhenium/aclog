# -*- encoding: utf-8 -*-
require "spec_helper"

describe TweetsHelper do
  describe "#html_favoriters_limit" do
    subject { helper.html_favoriters_limit }

    context "when timeline" do
      before { controller.request.format = :html }
      it { should eq Settings.tweets.users.count_default }
    end

    context "when tweet" do
      before do
        controller.request.format = :html
        params[:action] = "show"
      end
      it { should eq Settings.tweets.users.count_lot }
    end

    context "when tweet with full=true parameter" do
      before do
        controller.request.format = :html
        params[:action] = "show"
        params[:full] = "true"
      end
      it { should be nil }
    end
  end

  describe "#html_favoriters_truncated?" do
    let(:user) { FactoryGirl.create(:user) }
    subject { helper.html_favoriters_truncated?(tweet) }
    context "when full=true" do
      before { helper.stub(:html_favoriters_limit).and_return(nil) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.users.count_lot + 1, retweets_count: Settings.tweets.users.count_lot + 1) }
      it { should be false }
    end
    context "when _count equals count_default" do
      before { helper.stub(:html_favoriters_limit).and_return(Settings.tweets.users.count_default) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.users.count_default, retweets_count: Settings.tweets.users.count_default) }
      it { should be false }
    end
    context "when _count is larger than count_default" do
      before { helper.stub(:html_favoriters_limit).and_return(Settings.tweets.users.count_default) }
      let(:tweet) { FactoryGirl.create(:tweet, user: user, favorites_count: Settings.tweets.users.count_default, retweets_count: Settings.tweets.users.count_default + 1) }
      it { should be true }
    end
  end
end

