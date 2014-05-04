require "spec_helper"

describe User do
  subject(:user) { create(:user) }

  describe ".find" do
    context "when specify Fixnum" do
      it "returns user if exists" do
        expect(User.find(user.id)).to eq user
      end
      it "raises ActiveRecord::RecordNotFound if doesn't exist" do
        expect { User.find(-1) }.to raise_error ActiveRecord::RecordNotFound
      end
    end
    context "when specify Hash" do
      it "returns user specified by id when both specified" do
        user2 = create(:user)
        expect(User.find(id: user.id, screen_name: user2.screen_name)).to eq user
      end
      it "returns user when only id specified" do
        expect(User.find(id: user.id)).to eq user
      end
      it "returns user when only screen_name specified" do
        expect(User.find(screen_name: user.screen_name)).to eq user
      end
      it "raises ActiveRecord::RecordNotFound if user with specified id doesn't exist" do
        expect { User.find(id: -1) }.to raise_error ActiveRecord::RecordNotFound
      end
      it "raises ActiveRecord::RecordNotFound if user with specified screen_name doesn't exist" do
        expect { User.find(screen_name: "123456789012345678901") }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe ".create_from_json" do
    it "updates the record if already exists" do
      s = user.screen_name + "_new"
      expect(User.create_from_json(build(:user, screen_name: s)).reload.screen_name).to eq s
    end
    it "creates new record if doesn't exist" do
      expect(User.create_from_json(build(:user, id: user.id + 1)).reload.id).to be(user.id + 1)
    end
    it "doesn't update the record if not changed" do
      user.update(updated_at: user.updated_at - 1000)
      old_updated_at = user.reload.updated_at
      expect(User.create_from_json(user.attributes.symbolize_keys).reload.updated_at).to eq old_updated_at
    end
  end

  describe "#twitter_url" do
    it "returns URL of user's own user page on twitter.com" do
      expect(user.twitter_url).to eq "https://twitter.com/#{user.screen_name}"
    end
  end

  describe "#profile_image_url_original" do
    it "returns the URL of user's profile image with no size option" do
      user.profile_image_url = "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx_normal.png"
      expect(user.profile_image_url_original).to eq "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx.png"
    end
  end

  describe "#profile_image_url_reasonably_small" do
    it "returns the URL of user's profile image with no size option" do
      user.profile_image_url = "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx_normal.png"
      expect(user.profile_image_url_reasonably_small).to eq "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx_reasonably_small.png"
    end
  end

  describe "#profile_image_url_bigger" do
    it "returns the URL of user's profile image with no size option" do
      user.profile_image_url = "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx_normal.png"
      expect(user.profile_image_url_bigger).to eq "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx_bigger.png"
    end
  end

  describe "#profile_image_url_mini" do
    it "returns the URL of user's profile image with no size option" do
      user.profile_image_url = "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx_normal.png"
      expect(user.profile_image_url_mini).to eq "https://pbs.twimg.com/profile_images/2284174758/v65oai7fxn47qv9nectx_mini.png"
    end
  end

  describe "#protected?" do
    it "returns true if user (Twitter) is protected" do
      user.protected = true
      expect(user.protected?).to be true
    end
    it "returns false if user (Twitter) isn't protected" do
      expect(user.protected?).to be false
    end
  end

  describe "#registered?" do
    context "user's record does exist" do
      before do
        @account = create(:account, user: user)
      end
      it "return true if user is active" do
        expect(user.registered?).to be true
      end
      it "return false if user is inactive" do
        @account.status = :inactive
        expect(user.registered?).to be false
      end
    end
    it "returns false if user's record doesn't exist" do
      expect(user.registered?).to be false
    end
  end

  describe "#private?" do
    context "user is registered" do
      it "returns true if user (aclog) is private" do
        account = create(:account, user: user, private: true)
        expect(user.private?).to be true
      end
      it "returns false if user (aclog) isn't private" do
        account = create(:account, user: user, private: false)
        expect(user.private?).to be false
      end
    end
    it "returns true if user (aclog) isn't registered" do
      expect(user.private?).to be true
    end
  end

  describe "#following?" do
    it "returns true if the user is following target" do
      user2 = create(:user)
      account = create(:account, user: user)
      account.stub(:following?).and_return(true)
      expect(user.following?(user2)).to be true
    end
    it "returns false if the user isn't following target" do
      user2 = create(:user)
      account = create(:account, user: user)
      allow(account).to receive(:following?) { false }
      expect(user.following?(user2)).to be false
    end
  end

  describe "#permitted_to_see?" do
    it "returns true unless the user is protected" do
      user2 = create(:user)
      expect(user.permitted_to_see?(user2)).to be true
    end
    it "returns true if the target user is the user" do
      expect(user.permitted_to_see?(user)).to be true
    end
    it "returns true if user is following the target user" do
      user2 = create(:user, protected: true)
      allow(user).to receive(:following?) { true }
      expect(user.permitted_to_see?(user2)).to be true
    end
    it "returns false if the target user is protected, not same, not following" do
      user2 = create(:user, protected: true)
      allow(user).to receive(:following?) { false }
      expect(user.permitted_to_see?(user2)).to be false
    end
  end

  describe "#stats" do
    it "returns the user's stats if registered" do
      create(:account, user: user)
      user_2, user_3 = create_list(:user, 2)
      tweet_1, tweet_2 = create_list(:tweet, 2, user: user)
      create(:favorite, tweet: tweet_1, user: user_2)
      create(:favorite, tweet: tweet_1, user: user_3)
      create(:favorite, tweet: tweet_1, user: user)
      create(:retweet,  tweet: tweet_2, user: user_2)
      tweet_1.update(favorites_count: 3, retweets_count: 0, reactions_count: 3)
      tweet_2.update(favorites_count: 0, retweets_count: 1, reactions_count: 1)

      stats = user.stats

      expect(stats.updated_at).to be_truthy
      expect(stats.since_join).to be_a Integer
      expect(stats.favorites_count).to be 1
      expect(stats.retweets_count).to be 0
      expect(stats.tweets_count).to be 2
      expect(stats.reactions_count).to be 4
    end
    it "raises Aclog::Exceptions::UserNotRegistered unless registered" do
      expect { user.stats }.to raise_error Aclog::Exceptions::UserNotRegistered
    end
  end

  describe "#count_discovered_by" do
    it "returns array of discoverer" do
      user_1, user_2 = create_list(:user, 2)
      tweet_1, tweet_2 = create_list(:tweet, 2, user: user)
      create(:favorite, tweet: tweet_1, user: user)
      create(:favorite, tweet: tweet_1, user: user_1)
      create(:retweet, tweet: tweet_1, user: user_1)
      create(:favorite, tweet: tweet_2, user: user_1)
      create(:favorite, tweet: tweet_1, user: user_2)
      create(:favorite, tweet: tweet_2, user: user_2)

      ret = user.count_discovered_by
      expect(ret).to eq [[user_1.id, 2, 1], [user_2.id, 2, 0], [user.id, 1, 0]]
    end
  end

  describe "#count_discovered_users" do
    it "returns array of discovered by the user" do
      user_1, user_2 = create_list(:user, 2)
      tweet_1 = create(:tweet, user: user_1)
      tweet_2 = create(:tweet, user: user_2)
      tweet_3 = create(:tweet, user: user_2)
      create(:favorite, tweet: tweet_1, user: user)
      create(:favorite, tweet: tweet_1, user: user_1)
      create(:retweet, tweet: tweet_1, user: user)
      create(:favorite, tweet: tweet_2, user: user)
      create(:retweet, tweet: tweet_2, user: user)
      create(:favorite, tweet: tweet_3, user: user)

      ret = user.count_discovered_users
      expect(ret).to eq [[user_2.id, 2, 1], [user_1.id, 1, 1]]
    end
  end
end
