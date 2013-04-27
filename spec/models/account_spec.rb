# -*- coding: utf-8 -*-
require 'spec_helper'

describe Account do
  describe ".create_or_update" do
    context "when not recorded" do
      let(:account) { FactoryGirl.build(:account_1) }
      subject { Account.create_or_update(account.attributes.symbolize_keys) }
      its(:user_id) { should be account.user_id }
      its(:oauth_token) { should eq account.oauth_token }
      its(:oauth_token_secret) { should eq account.oauth_token_secret }
      its(:consumer_version) { should be account.consumer_version }
    end

    context "when already recorded" do
      let(:old_account) { FactoryGirl.create(:account_1) }
      let(:new_account) { FactoryGirl.build(:account_2) }
      subject { Account.create_or_update(new_account.attributes.symbolize_keys) }
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
      it { should eq @user }
    end

    context "when not exist" do
      it { should be nil }
    end
  end

  describe "#update_connection" do
    let(:account) { FactoryGirl.create(:account_1) }
    it "should not raise error" do
      expect { account.update_connection }.not_to raise_error
    end
    # TODO: how to test receiver...?
  end

  describe "#client" do
    let(:account) { FactoryGirl.create(:account_1) }
    subject { account.client }
    it { should be_a Twitter::Client }
  end

  describe "#import_favorites" do
    # TODO
  end
end
