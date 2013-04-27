require 'spec_helper'

describe User do
  describe ".from_user_object" do
    context "when not recorded" do
      let(:user_1_model) { FactoryGirl.build(:user_1) }
      let(:user_object) { OpenStruct.new(id: user_1_model.id,
                                         screen_name: user_1_model.screen_name,
                                         name: user_1_model.name,
                                         profile_image_url_https: user_1_model.profile_image_url,
                                         protected: user_1_model.protected) }
      subject { User.from_user_object(user_object) }
      its(:id) { should be user_object.id }
      its(:screen_name) { should eq user_object.screen_name }
      its(:name) { should eq user_object.name }
      its(:profile_image_url) { should eq user_object.profile_image_url_https }
      its(:protected) { should be user_object.protected }
    end

    context "when already recorded" do
      let!(:user_1) { FactoryGirl.create(:user_1) }
      let(:user_2_model) { FactoryGirl.build(:user_2) }
      let(:user_object) { OpenStruct.new(id: user_2_model.id,
                                         screen_name: user_2_model.screen_name,
                                         name: user_2_model.name,
                                         profile_image_url_https: user_2_model.profile_image_url,
                                         protected: user_2_model.protected) }
      subject { User.from_user_object(user_object) }
      its(:id) { should be user_object.id }
      its(:id) { should be user_1.id }
      its(:screen_name) { should eq user_object.screen_name }
      its(:screen_name) { should eq user_1.screen_name }
      its(:name) { should eq user_object.name }
      its(:profile_image_url) { should eq user_object.profile_image_url_https }
      its(:protected) { should be user_object.protected }
    end
  end

  describe ".delete_cache" do
    # TODO
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
    before { user.stub!(:profile_image_url).and_return("https://example.com/profile_image_normal.png") }
    subject { user.profile_image_url_original }
    it { should eq "https://example.com/profile_image.png" }
  end

  describe "#stats" do
    let!(:account) { FactoryGirl.create(:account_1) }
    let(:user) { FactoryGirl.create(:user_1) }
    let(:stats_api) { {favorites_count: 10,
                       listed_count: 12,
                       followers_count: 14,
                       tweets_count: 16,
                       friends_count: 18,
                       bio: "abc"} }
    before do
      user_2, user_3 = FactoryGirl.create_list(:user, 2)
      tweet_1, tweet_2 = FactoryGirl.create_list(:tweet, 2, user: user)
      FactoryGirl.create(:favorite, tweet: tweet_1, user: user_2)
      FactoryGirl.create(:favorite, tweet: tweet_1, user: user_3)
      FactoryGirl.create(:retweet,  tweet: tweet_2, user: user_2)

      stub_request(:get, "https://api.twitter.com/1.1/account/verify_credentials.json")
        .to_return(status: 200, body: {id: user.id,
                                       favourites_count: 10,
                                       listed_count: 12,
                                       followers_count: 14,
                                       statuses_count: 16,
                                       friends_count: 18,
                                       description: "abc"}.to_json)
    end

    subject { OpenStruct.new(user.stats(true)) }
    its(:stats_api) { should eq stats_api }
    its(:favorites_count) { should be 0 }
    its(:retweets_count) { should be 0 }
    its(:tweets_count) { should be 2 }
    its(:favorited_count) { should be 2 }
    its(:retweeted_count) { should be 1 }
  end
end
