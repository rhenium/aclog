require "spec_helper"

describe Retweet do
  describe ".from_receiver" do
    let(:user_0) { FactoryGirl.create(:user) }
    let(:user_1) { FactoryGirl.create(:user) }
    let(:hash) { {"id" => 1234,
                  "tweet" => {"id" => 123,
                              "text" => "abc",
                              "source" => "web",
                              "tweeted_at" => Time.now.to_s,
                              "user" => {"id" => user_0.id}},
                  "user" => {"id" => user_1.id}} }
    subject { Retweet.from_receiver(hash) }
    its(:id) { should be hash["id"] }
    its(:tweet_id) { should be hash["tweet"]["id"] }
    its(:user_id) { should be hash["user"]["id"] }
  end
end
