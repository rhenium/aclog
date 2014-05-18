require "spec_helper"

describe Favorite do
  subject(:user) { create(:user) }
  subject(:tweet) { create(:tweet, user: user, favorites_count: 1, reactions_count: 1) }
  subject(:favoriter) { create(:user) }
  subject(:favorite) { create(:favorite, tweet: tweet, user: favoriter) }

  describe "create_bulk_from_json" do
    before do
      @args = [{ source: { id: favoriter.id },
                 target_object: { id: tweet.id,
                                  user: { id: user.id } } }]
    end
    it "creates new favorite" do
      favorite.destroy
      Favorite.create_bulk_from_json(@args)
      f = Favorite.where(user: user, tweet: tweet)
      expect(f).not_to be nil
    end
    it "ignores errors if already exists" do
      expect { Favorite.create_bulk_from_json(@args) }.not_to raise_error
    end
  end

  describe "delete_bulk_from_json" do
    it "destorys the favorite" do
      Favorite.delete_bulk_from_json([{ source: { id: favorite.user_id }, target_object: { id: favorite.tweet_id } }])
      expect { favorite.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
