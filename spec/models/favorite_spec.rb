require "spec_helper"

describe Retweet do
  subject(:user) { create(:user) }
  subject(:tweet) { create(:tweet, user: user, favorites_count: 1, reactions_count: 1) }
  subject(:favoriter) { create(:user) }
  subject(:favorite) { create(:favorite, tweet: tweet, user: favoriter) }

  describe "create_from_json" do
    before do
      @args = { source: {},
                target_object: {} }
      allow(Tweet).to receive(:create_from_json) { tweet }
      allow(User).to receive(:create_from_json) { favoriter }
    end
    it "creates new favorite and increment favorites_count" do
      favorite.destroy
      old_favs = tweet.reload.favorites_count
      ret = Favorite.create_from_json(@args)
      expect(ret.tweet).to eq tweet
      expect(ret.user).to eq favoriter
      expect(tweet.reload.favorites_count).to be(old_favs + 1)
    end
    it "ignores ActiveRecord::RecordNotUnique and returns favorite" do
      expect { Favorite.create_from_json(@args) }.to_not raise_error
      expect(Favorite.create_from_json(@args).user).to eq favoriter
    end
  end

  describe "destroy_from_json" do
    it "destorys the favorite and decrement favorites_count" do
      old_favs = tweet.reload.favorites_count
      Favorite.destroy_from_json(source: { id: favorite.user_id }, target_object: { id: favorite.tweet_id })
      expect { favorite.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(tweet.reload.favorites_count).to be(old_favs - 1)
    end
  end
end
