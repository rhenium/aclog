require 'spec_helper'

describe Account do
  describe ".create_or_update" do
    context "when not recorded" do
      let(:account) { FactoryGirl.build(:account_1) }
      subject { Account.create_or_update(account.attributes.symbolize_keys) }
      its(:user_id) { should be account.user_id }
      its(:oauth_token) { should eq account.oauth_token }
      its(:oauth_token_secret) { should eq account.oauth_token_secret }
      its(:status) { should be Account::ACTIVE }
    end

    context "when already recorded" do
      before {
        @old_account = FactoryGirl.create(:account_1)
        @old_account.update!(notification: false, private: true)
      }
      let(:new_account) { FactoryGirl.build(:account_2) }
      subject { Account.create_or_update(new_account.attributes.symbolize_keys) }
      its(:id) { should be @old_account.id }
      its(:user_id) { should be @old_account.user_id }
      its(:user_id) { should be new_account.user_id }
      its(:oauth_token) { should eq new_account.oauth_token }
      its(:oauth_token_secret) { should eq new_account.oauth_token_secret }
      its(:notification) { should be false }
      its(:private) { should be true }
      its(:status) { should be Account::ACTIVE }
    end
  end

  describe ".set_of_collector" do
    before { Settings.collector.stub(:count).and_return(3) }
    let!(:accounts) { 10.times.map {|i| Account.create!(user_id: i, oauth_token: "abc", oauth_token_secret: "def") } }
    subject { Account.set_of_collector(2) }
    it { should_not include -> m { m.id % 3 != 2 } }
  end

  describe "#notification?" do
    context "when enabled" do
      let(:account) { FactoryGirl.create(:account_1, notification: true) }
      subject { account }
      its(:notification?) { should be true }
    end

    context "when disabled" do
      let(:account) { FactoryGirl.create(:account_1, notification: false) }
      subject { account }
      its(:notification?) { should be false }
    end
  end

  describe "#private?" do
    context "when private" do
      let(:account) { FactoryGirl.create(:account_1, private: true) }
      subject { account }
      its(:private?) { should be true }
    end

    context "when public" do
      let(:account) { FactoryGirl.create(:account_1, private: false) }
      subject { account }
      its(:private?) { should be false }
    end
  end

  describe "#active?" do
    let(:account) { FactoryGirl.create(:account_1) }
    context "when active" do
      subject { account }
      its(:active?) { should be true }
    end

    context "when inactive" do
      subject { account.tap(&:deactivate!) }
      its(:active?) { should be false }
    end
  end

  describe "#deactivate!" do
    let(:account) { FactoryGirl.create(:account_1) }
    it { account.active?.should be true }
    subject { account.tap(&:deactivate!) }
    its(:active?) { should be false }
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
    it { subject.__send__(:credentials)[:token].should eq account.oauth_token }
  end

  describe "#import_favorites" do
    # TODO
  end

  describe "#api_friendship?" do
    before do
      stub_request(:get, "https://api.twitter.com/1.1/friendships/show.json?source_id=1326331596&target_id=456").
         to_return(status: 200, body: '{"relationship":{"source":{"followed_by":false,"screen_name":"aclog_test","id_str":"1326331596","blocking":null,"want_retweets":null,"notifications_enabled":null,"id":1326331596,"all_replies":null,"can_dm":false,"following":false,"marked_spam":null},"target":{"followed_by":false,"screen_name":"davegray","id_str":"456","id":456,"following":false}}}')
      stub_request(:get, "https://api.twitter.com/1.1/friendships/show.json?source_id=1326331596&target_id=280414022").
         to_return(status: 200, body: '{"relationship":{"source":{"notifications_enabled":null,"screen_name":"aclog_test","followed_by":true,"all_replies":null,"id_str":"1326331596","marked_spam":null,"id":1326331596,"want_retweets":null,"blocking":null,"can_dm":true,"following":true},"target":{"screen_name":"cn","followed_by":true,"id_str":"280414022","id":280414022,"following":true}}}')
    end
    let(:account) { FactoryGirl.create(:account_1) }
    context "when not following" do
      let(:source_user_id) { account.user_id }
      let(:target_user_id) { 456 }
      subject { account.__send__(:api_friendship?, source_user_id, target_user_id) }
      it { should be false }
    end

    context "when following" do
      let(:source_user_id) { account.user_id }
      let(:target_user_id) { 280414022 } # @cn
      subject { account.__send__(:api_friendship?, source_user_id, target_user_id) }
      it { should be true }
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

end
