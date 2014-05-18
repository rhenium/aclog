require "spec_helper"

describe Retweet do
  subject(:user) { create(:user) }
  subject(:tweet) { create(:tweet, user: user, retweets_count: 1, reactions_count: 1) }
  subject(:retweeter) { create(:user) }
  subject(:retweet) { create(:retweet, tweet: tweet, user: retweeter) }

  describe "create_bulk_from_json" do
    before do
      @args = [{ id: retweet.id,
                 user: { id: retweeter.id },
                 retweeted_status: { id: tweet.id,
                                     user: { id: user.id } } }]
    end
    it "creates new retweet" do
      Retweet.create_bulk_from_json(@args.merge(id: retweet.id + 1))
      r = Retweet.where(user: user, tweet: tweet)
      expect(ret.count).to be 2
      expect(ret.order(id: :desc).first.id).to be retweet.id + 1
    end
    it "ignores errors if already exists" do
      expect { Retweet.create_bulk_from_json(@args) }.not_to raise_error
    end
  end

  describe "delete_bulk_from_json" do
    it "destorys the retweet" do
      Retweet.delete_bulk_from_json(delete: { status: { id: retweet.id, user_id: retweeter.id } })
      expect { retweet.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
