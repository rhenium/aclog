require 'spec_helper'

describe User do
  describe "#twitter_url" do
    let(:user) { FactoryGirl.build(:user_1) }
    subject { user.twitter_url }
    it { should eq "https://twitter.com/#{user.screen_name}" }
  end

  describe ".find" do
    let(:user) { FactoryGirl.create(:user) }

    context "when user exists" do
      subject { User.find(id: id, screen_name: screen_name) }

      context "and specify only id" do
        let(:id) { user.id }
        let(:screen_name) { nil }
        it { should eq user }
      end

      context  "and specify only screen_name" do
        let(:id) { nil }
        let(:screen_name) { user.screen_name }
        it { should eq user }
      end
    end

    context "when user not exists" do
      subject { -> { User.find(id: id, screen_name: screen_name) } }

      context "when specify not existing id" do
        let(:id) { user.id + 1 }
        let(:screen_name) { nil }
        it { should raise_error ActiveRecord::RecordNotFound }
      end

      context  "when specify only screen_name" do
        let(:id) { nil }
        let(:screen_name) { "1234567890abcdef" }
        it { should raise_error ActiveRecord::RecordNotFound }
      end
    end
  end

  describe "#protected?" do
    context "when not protected" do
      let(:user) { FactoryGirl.create(:user, protected: false) }
      subject { user }
      its(:protected?) { should be false }
    end

    context "when protected" do
      let(:user) { FactoryGirl.create(:user, protected: true) }
      subject { user }
      its(:protected?) { should be true }
    end
  end

  describe "#account" do
    context "when exists" do
      let!(:account) { FactoryGirl.create(:account_1) }
      let(:user) { FactoryGirl.create(:user_1) }
      subject { user.account }
      it { should eq account }
    end

    context "when not exists" do
      let!(:account) { FactoryGirl.create(:account_1) }
      let(:user) { FactoryGirl.create(:user_exists) }
      subject { user.account }
      it { should be nil }
    end
  end

  describe "#profile_image_url_original" do
    let(:user) { FactoryGirl.create(:user) }
    before { user.stub(:profile_image_url).and_return("https://example.com/profile_image_normal.png") }
    subject { user.profile_image_url_original }
    it { should eq "https://example.com/profile_image.png" }
  end

  describe "#stats" do
    let!(:account) { FactoryGirl.create(:account_1) }
    let(:user) { FactoryGirl.create(:user_1) }
    before do
      user_2, user_3 = FactoryGirl.create_list(:user, 2)
      tweet_1, tweet_2 = FactoryGirl.create_list(:tweet, 2, user: user)
      FactoryGirl.create(:favorite, tweet: tweet_1, user: user_2)
      FactoryGirl.create(:favorite, tweet: tweet_1, user: user_3)
      FactoryGirl.create(:retweet,  tweet: tweet_2, user: user_2)
    end

    subject { user.stats }
    its(:updated_at) { should_not be nil }
    its(:since_join) { should be_a Integer }
    its(:favorites_count) { should be 0 }
    its(:retweets_count) { should be 0 }
    its(:tweets_count) { should be 2 }
    its(:reactions_count) { should be 3 }
  end

  describe "#count_discovered_by" do
    before do
      @user = FactoryGirl.create_list(:user, 3)
      tweet_1, tweet_2 = FactoryGirl.create_list(:tweet, 2, user: @user[0])
      FactoryGirl.create(:favorite, tweet: tweet_1, user: @user[0])
      FactoryGirl.create(:favorite, tweet: tweet_1, user: @user[1])
      FactoryGirl.create(:retweet, tweet: tweet_1, user: @user[1])
      FactoryGirl.create(:favorite, tweet: tweet_2, user: @user[1])
      FactoryGirl.create(:favorite, tweet: tweet_1, user: @user[2])
      FactoryGirl.create(:favorite, tweet: tweet_2, user: @user[2])
    end
    subject { @user.first.count_discovered_by }
    its(:size) { should be 3 }
    it { should eq [[@user[1].id, 2, 1], [@user[2].id, 2, 0], [@user[0].id, 1, 0]] }
  end

  describe "#count_discovered_users" do
    before do
      @user = FactoryGirl.create_list(:user, 3)
      tweet_1 = FactoryGirl.create(:tweet, user: @user[1])
      tweet_2 = FactoryGirl.create(:tweet, user: @user[2])
      tweet_3 = FactoryGirl.create(:tweet, user: @user[2])
      FactoryGirl.create(:favorite, tweet: tweet_1, user: @user[0])
      FactoryGirl.create(:favorite, tweet: tweet_1, user: @user[1])
      FactoryGirl.create(:retweet, tweet: tweet_1, user: @user[0])
      FactoryGirl.create(:favorite, tweet: tweet_2, user: @user[0])
      FactoryGirl.create(:retweet, tweet: tweet_2, user: @user[0])
      FactoryGirl.create(:favorite, tweet: tweet_3, user: @user[0])
    end
    subject { @user[0].count_discovered_users }
    its(:size) { should be 2 }
    it { should eq [[@user[2].id, 2, 1], [@user[1].id, 1, 1]] }
  end
end
