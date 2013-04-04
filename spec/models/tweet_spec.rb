# -*- coding: utf-8 -*-
require 'spec_helper'

describe Tweet do
  context "scopes" do
    before :all do
      @favoriters = []
      @retweeters = []
      @created_users = FactoryGirl.create_list(:user, 5)
      @created_users.each do |u|
        ts = FactoryGirl.create_list(:tweet, 3, user: u)
        us = @created_users.reject{|m| m == u} # 4

        # favs: 3, 1, 0
        us.shuffle.take(3).each do |m|
          FactoryGirl.create(:favorite, tweet: ts[0], user: m)
          @favoriters << m
        end
        _s = us.shuffle[1]
        FactoryGirl.create(:favorite, tweet: ts[1], user: _s)
        @favoriters << _s

        # rts: 2, 1, 0
        us.shuffle.take(2).each do |m|
          FactoryGirl.create(:retweet, tweet: ts[0], user: m)
          @retweeters << m
        end
        _m = us.shuffle[1]
        FactoryGirl.create(:retweet, tweet: ts[1], user: _m)
        @retweeters << _m
      end
      @favoriters.uniq!
      @retweeters.uniq!
    end
    after :all do
      @created_users.map(&:destroy)
    end

    it "3日分" do
      tweets = Tweet.recent
      tweets.should_not include -> tweet {tweet.tweeted_at < Time.zone.now - 3.days}
    end

    it "反応があった分" do
      tweets = Tweet.reacted
      tweets.should_not include -> tweet {tweet.favorites_count + tweet.retweets_count == 0}
    end

    it "新しい順" do
      tweets = Tweet.order_by_id.limit(2)
      tweets.first.id.should be > tweets.last.id
    end

    it "ふぁぼ数順" do
      tweets = Tweet.order_by_favorites
      tweets.first.favorites.count.should be >= tweets.last.favorites.count
    end

    it "RT数順" do
      tweets = Tweet.order_by_retweets
      tweets.first.retweets.count.should be >= tweets.last.retweets.count
    end

    it "反応数順" do
      tweets = Tweet.order_by_reactions.limit(2)
      tweets.first.retweets.count.should be >= tweets.last.retweets.count
    end

    it "ユーザーにふぁぼられたツイート" do
      tweets = Tweet.favorited_by(@favoriters.first)
      tweets.should_not include -> tweet {tweet.user_id != @favoriters.first.id}
    end

    it "ユーザーにRTされたツイート" do
      tweets = Tweet.retweeted_by(@retweeters.first)
      tweets.should_not include -> tweet {tweet.user_id != @retweeters.first.id}
    end

    it "ユーザーが反応したツイート" do
      user = (@favoriters + @retweeters).sample
      tweets = Tweet.favorited_by(user)
      tweets.should_not include -> tweet {tweet.user_id != user.id}
    end

    it "オリジナルのツイート" do
      # TODO
    end
  end

  context "class methods" do
    it "Tweet.cached" do
      # TODO
    end
  end
end
