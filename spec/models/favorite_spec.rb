require "spec_helper"

describe Favorite do
  describe ".from_receiver" do
    let(:user_0) { FactoryGirl.create(:user) }
    let(:user_1) { FactoryGirl.create(:user) }
    let(:hash) { {"tweet" => {"id" => 123,
                              "text" => "abc",
                              "source" => "web",
                              "tweeted_at" => Time.now.to_s,
                              "user" => {"id" => user_0.id}},
                  "user" => {"id" => user_1.id}} }
    subject { Favorite.from_receiver(hash) }
    its(:tweet_id) { should be hash["tweet"]["id"] }
    its(:user_id) { should be hash["user"]["id"] }
  end
end
