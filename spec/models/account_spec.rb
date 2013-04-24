# -*- coding: utf-8 -*-
require 'spec_helper'

describe Account do
  describe ".register_or_update" do
    context "when not recorded" do
      let(:account) { FactoryGirl.build(:account_1) }
      subject { Account.register_or_update(account.attributes.symbolize_keys) }
      its(:user_id) { should be account.user_id }
      its(:oauth_token) { should eq account.oauth_token }
      its(:oauth_token_secret) { should eq account.oauth_token_secret }
      its(:consumer_version) { should be account.consumer_version }
    end

    context "when already recorded" do
      let(:old_account) { FactoryGirl.create(:account_1) }
      let(:new_account) { FactoryGirl.build(:account_2) }
      subject { Account.register_or_update(new_account.attributes.symbolize_keys) }
      its(:id) { should be old_account.id }
      its(:user_id) { should be old_account.user_id }
      its(:user_id) { should be new_account.user_id }
      its(:oauth_token) { should eq new_account.oauth_token }
      its(:oauth_token_secret) { should eq new_account.oauth_token_secret }
      its(:consumer_version) { should eq new_account.consumer_version }
    end
  end

  describe "#user" do
    let(:account) { FactoryGirl.create(:account_1) }
    subject { account.user }

    context "when exist" do
      before { @user = FactoryGirl.create(:user_1) }
      it { should_not eq nil }
      it { should eq @user }
    end

    context "when not exist" do
      it { should be nil }
    end
  end

  describe "#client" do
    let(:account) { FactoryGirl.create(:account_1) }
    subject { account.client }
    it { should be_a Twitter::Client }
  end

  describe "#twitter_user" do
    let(:account) { FactoryGirl.create(:account_1) }
    let(:user) { FactoryGirl.create(user_fixture) }
    subject { account.twitter_user(user.id) }

    context "when exist" do
      let(:user_fixture) { :user_exists }
      its(:id) { should be user.id }
      its(:screen_name) { should eq user.screen_name }
    end

    context "when not exist" do
      let(:user_fixture) { :user_not_exists }
      it { should be nil }
    end

    context "when suspended" do
      let(:user_fixture) { :user_suspended }
      it { should be nil }
    end

    context "when no parameter" do
      let(:user_fixture) { :user_1 }
      before { user }
      subject { account.twitter_user }
      its(:id) { should be user.id }
      its(:screen_name) { should eq user.screen_name }
    end
  end

  describe "#import_favorites" do
    # TODO
  end

  describe "#stats_api" do
    let(:account) { FactoryGirl.create(:account_1) }
    let(:tweet) { OpenStruct.new(favourites_count: 10,
                                 listed_count: 12,
                                 followers_count: 14,
                                 statuses_count: 16,
                                 friends_count: 18,
                                 description: "") }
    before { account.stub!(:twitter_user).and_return(tweet) }
    subject { OpenStruct.new(account.stats_api) }
    its(:favorites_count) { should be tweet.favourites_count }
    its(:listed_count) { should be tweet.listed_count }
    its(:followers_count) { should be tweet.followers_count }
    its(:tweets_count) { should be tweet.statuses_count }
    its(:friends_count) { should be tweet.friends_count }
    its(:bio) { should eq tweet.description }
  end
end
