require "spec_helper"

describe Tweet do
  subject(:user) { FactoryGirl.create(:user) }
  subject(:tweet) { FactoryGirl.create(:tweet, user: user) }

  pending "scopes"

  describe "create_from_json" do
    before do
      @args = { id: tweet.id,
                text: tweet.text,
                entities: {},
                source: tweet.source,
                created_at: Time.now.to_s,
                in_reply_to_status_id: nil,
                user: nil }
    end
    it "creates new record if doesn't exist" do
      allow(User).to receive(:create_from_json).with(nil) { user }
      tweet2 = Tweet.create_from_json(@args.merge(id: tweet.id + 1, text: tweet.text + "_new"))
      tweet2 = tweet2.reload
      expect(tweet2.id).to be(@args[:id] + 1)
      expect(tweet2.text).to eq(@args[:text] + "_new")
      expect(tweet2.source).to eq @args[:source]
      expect(tweet2.tweeted_at).to eq Time.parse(@args[:created_at])
      expect(tweet2.in_reply_to_id).to be @args[:in_reply_to_status_id]
      expect(tweet2.user_id).to be user.id
    end
    it "returns the record if already exists" do
      tweet2 = Tweet.create_from_json(@args.merge(text: tweet.text + "_new"))
      tweet2 = tweet2.reload
      expect(tweet2.text).to eq tweet.text
    end
    it "ignores ActiveRecord::RecordNotUnique and returns tweet" do
      allow(User).to receive(:create_from_json).with(nil) { user }
      allow(Tweet).to receive(:find_by).with(id: tweet.id) { nil }
      expect { Tweet.create_from_json(@args) }.to_not raise_error
      expect(Tweet.create_from_json(@args.merge(text: tweet.text + "_new")).text).to eq tweet.text
    end
  end

  describe "create_from_twitter_object" do
    before do
      @args = { id: tweet.id,
                text: tweet.text,
                entities: {},
                source: tweet.source,
                created_at: Time.now.to_s,
                in_reply_to_status_id: nil,
                user: nil }
    end
    it "creates new record if doesn't exist" do
      allow(User).to receive(:create_from_json).with(nil) { user }
      tweet2 = Tweet.create_from_twitter_object(Twitter::Tweet.new(@args.merge(id: tweet.id + 1, text: tweet.text + "_new")))
      tweet2 = tweet2.reload
      expect(tweet2.id).to be(@args[:id] + 1)
      expect(tweet2.text).to eq(@args[:text] + "_new")
      expect(tweet2.source).to eq @args[:source]
      expect(tweet2.tweeted_at).to eq Time.parse(@args[:created_at])
      expect(tweet2.in_reply_to_id).to be @args[:in_reply_to_status_id]
      expect(tweet2.user_id).to be user.id
    end
    it "returns the record if already exists" do
      tweet2 = Tweet.create_from_twitter_object(Twitter::Tweet.new(@args.merge(text: tweet.text + "_new")))
      tweet2 = tweet2.reload
      expect(tweet2.text).to eq tweet.text
    end
  end

  describe "destory_from_json" do
    it "destroys the tweet and favorites and retweets and returns true" do
      f = create(:favorite, tweet: tweet, user: user)
      r = create(:retweet, tweet: tweet, user: user)
      expect(Tweet.destroy_from_json(delete: { status: { id: tweet.id, user_id: user.id } })).to be true
      expect { tweet.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { f.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { r.reload }.to raise_error ActiveRecord::RecordNotFound
    end
    it "returns false if the tweet doesn't exist" do
      expect(Tweet.destroy_from_json(delete: { status: { id: -1, user_id: -1 } })).to be false
    end
  end

  describe "import" do
    before do
      @args = { id: tweet.id,
                text: tweet.text + "_new",
                entities: {},
                source: tweet.source,
                created_at: Time.now.to_s,
                favorite_count: 12345,
                retweet_count: 23456,
                in_reply_to_status_id: nil,
                user: nil }
    end
    it "updates the tweet data from Twitter API" do
      account = create(:account, user: user)
      allow(account).to receive(:status).with(tweet.id) { Twitter::Tweet.new(@args) }
      ret = Tweet.import(tweet.id, account)
      expect(ret.text).to eq @args[:text]
      expect(ret.favorites_count).to be @args[:favorite_count]
      expect(ret.retweets_count).to be @args[:retweet_count]
      expect(ret.reactions_count).to be(@args[:favorite_count] + @args[:retweet_count])
    end
  end

  describe "filter_by_query" do
    pending
  end

  describe "extract_entities" do
    it "extracts a URL in tweet json hash" do
      json = { text: "@rhe__ https://t.co/jlEc2sg2UU #hashtag $symbol",
               entities: { urls: [{ url: "https://t.co/jlEc2sg2UU",
                                    expanded_url: "https://rhe.jp",
                                    display_url: "rhe.jp",
                                    indices: [7, 30] }] } }
      expect(Tweet.__send__(:extract_entities, json)).to eq "@rhe__ https://rhe.jp #hashtag $symbol"
    end
    it "extracts a media URL in tweet json hash" do
      json = { text: "@rhe__ https://t.co/jlEc2sg2UU #hashtag $symbol",
               entities: { media: [{ url: "https://t.co/jlEc2sg2UU",
                                     expanded_url: "https://rhe.jp",
                                     display_url: "rhe.jp",
                                     indices: [7, 30] }] } }
      expect(Tweet.__send__(:extract_entities, json)).to eq "@rhe__ https://rhe.jp #hashtag $symbol"
    end
  end

  describe "snowflake_min" do
    pending
  end

  describe "#twitter_url" do
    it "returns the URL of the tweet on twitter.com" do
      expect(tweet.twitter_url).to eq "https://twitter.com/#{user.screen_name}/status/#{tweet.id}"
    end
  end

  describe "#reply_ancestors" do
    it "returns reply_to of the tweet recursively" do
      tweet4 = create(:tweet, user: user)
      tweet3 = create(:tweet, user: user, in_reply_to: tweet4)
      tweet2 = create(:tweet, user: user, in_reply_to: tweet3)
      tweet.update(in_reply_to: tweet2)
      expect(tweet.reply_ancestors(2).map(&:id)).to eq [tweet2.id, tweet3.id]
    end
  end

  describe "#reply_descendants" do
    it "returns replies to the tweet recursively" do
      tweet21 = create(:tweet, user: user, in_reply_to: tweet)
      tweet22 = create(:tweet, user: user, in_reply_to: tweet)
      tweet3 = create(:tweet, user: user, in_reply_to: tweet21)
      tweet4 = create(:tweet, user: user, in_reply_to: tweet3)
      expect(tweet.reply_descendants(2).map(&:id)).to eq [tweet21.id, tweet22.id, tweet3.id]
    end
  end

  describe "#update_reactions_count" do
    it "updates *_counts to the greatest value: between before value + incrementation / decrementation and the values from Twitter json" do
      tweet.update(favorites_count: 1, retweets_count: 2, reactions_count: 3)
      tweet.update_reactions_count(favorites_count: 1, retweets_count: -1, json: { favorite_count: 4, retweet_count: 0 })
      tweet.reload
      expect(tweet.favorites_count).to be 4
      expect(tweet.retweets_count).to be 1
      expect(tweet.reactions_count).to be 5
    end
  end

=begin
  context "scopes" do
    describe "recent" do
      subject { Tweet.recent(3) }
      it { should_not include -> tweet { tweet.tweeted_at < Time.now - 3.days } }
      #its(:count) { should be 2 }
    end

    describe "reacted" do
      subject { Tweet.reacted }
      it { should_not include -> tweet { tweet.favorites_count + tweet.retweets_count == 0 } }
      #its(:count) { should be 3 }
    end

    describe "not_protected" do
      subject { Tweet.not_protected.includes(:user) }
      it { should_not include -> tweet { tweet.user.protected? } }
    end

    describe "max_id" do
      subject { Tweet.max_id(@tweet_0_0.id - 1) }
      #its(:count) { should be 2 }
      it { should_not include -> tweet { tweet.id > @tweet_0_0.id - 1 } }
    end

    describe "since_id" do
      subject { Tweet.since_id(@tweet_0_0.id) }
      #its(:count) { should be 1 }
      it { should_not include -> tweet { tweet.id <= @tweet_0_0.id } }
    end

    describe "page" do
      subject { Tweet.limit(3).page(2) }
      #its(:count) { should be 1 }
    end

    describe "order_by_id" do
      subject { Tweet.order_by_id }
      it { subject.first.id.should be > subject.last.id }
    end

    describe "order_by_reactions" do
      subject { Tweet.order_by_reactions }
      it {
        (subject.first.favorites.count + subject.first.retweets.count)
           .should be >= (subject.last.favorites.count + subject.last.retweets.count)
      }
    end

    describe "favorited_by" do
      subject { Tweet.favorited_by(@user_1) }
      #its(:count) { should be 2 }
      it { should_not include -> tweet { not tweet.favorites.any? {|a| a.user_id == @user_1.id } } }
    end

    describe "retweeted_by" do
      subject { Tweet.retweeted_by(@user_2) }
      #its(:count) { should be 1 }
      it { should_not include -> tweet { not tweet.retweets.any? {|a| a.user_id == @user_2.id } } }
    end

    describe "discovered_by" do
      subject { Tweet.discovered_by(@user_1) }
      #its(:count) { should be 3 }
      it { subject.select {|m| m.favorites.any? {|n| n.user_id == @user_1.id } }.count.should be 2 }
      it { subject.select {|m| m.retweets.any? {|n| n.user_id == @user_1.id } }.count.should be 1 }
      it { should_not include -> tweet { not (tweet.retweets + tweet.favorites).any? {|a| a.user_id == @user_1.id } } }
    end
  end
=end
end
