require "spec_helper"

describe Favorite do
  describe ".from_receiver" do
    let(:user_0) { FactoryGirl.create(:user) }
    let(:user_1) { FactoryGirl.create(:user) }
    let(:hash) { {"target_object" => {"id" => 123,
                                      "text" => "abc",
                                      "entities" => {},
                                      "source" => "web",
                                      "created_at" => Time.now.to_s,
                                      "user" => {"id" => user_0.id}},
                  "source" => {"id" => user_1.id}} }
    subject { Favorite.from_receiver(hash) }
    its(:tweet_id) { should be hash["target_object"]["id"] }
    its(:user_id) { should be hash["source"]["id"] }
  end
end
