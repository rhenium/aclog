require "spec_helper"

describe Retweet do
  subject(:user) { create(:user) }
  subject(:tweet) { create(:tweet, user: user, retweets_count: 1, reactions_count: 1) }
  subject(:retweeter) { create(:user) }
  subject(:retweet) { create(:retweet, tweet: tweet, user: retweeter) }

  describe "create_from_json" do
    before do
      @args = { id: retweet.id,
                user: {},
                retweeted_status: {} }
    end
    it "creates new retweet and increment retweets_count" do
      allow(Tweet).to receive(:create_from_json) { tweet }
      allow(User).to receive(:create_from_json) { retweeter }
      old_rts = tweet.reload.retweets_count
      ret = Retweet.create_from_json(@args.merge(id: retweet.id + 1))
      expect(ret.tweet).to eq tweet
      expect(ret.user).to eq retweeter
      expect(tweet.reload.retweets_count).to be(old_rts + 1)
    end
    it "ignores ActiveRecord::RecordNotUnique and returns retweet" do
      user2 = create(:user)
      allow(Tweet).to receive(:create_from_json) { tweet }
      allow(User).to receive(:create_from_json) { user2 }
      expect { Retweet.create_from_json(@args) }.to_not raise_error
      expect(Retweet.create_from_json(@args).user).to eq retweeter
    end
  end

  describe "destroy_from_json" do
    it "destorys the retweet and decrement retweets_count" do
      old_rts = tweet.reload.retweets_count
      Retweet.destroy_from_json(delete: { status: { id: retweet.id, user_id: retweeter.id } })
      expect { retweet.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(tweet.reload.retweets_count).to be(old_rts - 1)
    end
  end
end
