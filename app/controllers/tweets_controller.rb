# -*- encoding: utf-8 -*-
class TweetsController < ApplicationController
  def show
    tweet_required
    @caption = "#{@user.screen_name}'s Tweet"
  end

  def index
    user_required
    best rescue timeline
  end

  def best
    user_required
    check_public!
    @caption = "#{@user.screen_name}'s Best"
    @tweets = @user.tweets.reacted.order_by_reactions.list(params, force_page: true, cache: 3.minutes)
  end

  def favorited
    user_required
    check_public!
    @caption = "#{@user.screen_name}'s Most Favorited"
    @tweets = @user.tweets.reacted.order_by_favorites.list(params, force_page: true, cache: 3.minutes)
  end

  def retweeted
    user_required
    check_public!
    @caption = "#{@user.screen_name}'s Most Retweeted"
    @tweets = @user.tweets.reacted.order_by_retweets.list(params, force_page: true, cache: 3.minutes)
  end

  def recent
    user_required
    check_public!
    @caption = "#{@user.screen_name}'s Recent Best"
    @tweets = @user.tweets.recent.reacted.order_by_reactions.list(params, force_page: true, cache: 3.minutes)
  end

  def timeline
    user_required
    @caption = "#{@user.screen_name}'s Newest"
    @tweets = @user.tweets.reacted.order_by_id.list(params)
  end

  def discoveries
    user_required
    @caption = "#{@user.screen_name}'s Discoveries"
    @tweets = Tweet.discovered_by(@user).order_by_id.list(params)
  end

  def favorites
    user_required
    @caption = "#{@user.screen_name}'s Favorites"
    @tweets = Tweet.favorited_by(@user).order_by_id.list(params)
  end

  def retweets
    user_required
    @caption = "#{@user.screen_name}'s Retweets"
    @tweets = Tweet.retweeted_by(@user).order_by_id.list(params)
  end

  def discovered_by
    user_required
    user_b_required
    @caption = "Discovored by #{@user_b.screen_name}"
    @tweets = @user.tweets.discovered_by(@user_b).order_by_id.list(params)
  end

  def all_best
    @caption = "Top Tweets"
    @tweets = Tweet.reacted.order_by_reactions.list(params, force_page: true, cache: 3.hours)
  end

  def all_recent
    @caption = "Recent"
    @tweets = Tweet.recent.reacted.order_by_reactions.list(params, force_page: true, cache: 3.hours)
  end

  def all_timeline
    @caption = "Newest"
    @tweets = Tweet.reacted.order_by_id.list(params)
  end

  private
  def user_required
    @user = _require_user(params[:user_id], params[:screen_name])
  end

  def user_b_required
    @user_b = _require_user(params[:user_id_b], params[:screen_name_b])
  end

  def tweet_required
    @tweet = Tweet.find_by(id: params[:id])
    raise Aclog::Exceptions::TweetNotFound unless @tweet
    @user = _require_user(@tweet.user_id, nil)
  end

  def check_public!
    authorize_to_show_best!(@user)
  end

  def render(*args)
    if lookup_context.exists?(params[:action], params[:controller])
      super(*args)
    else
      super("_tweets")
    end
  end

  def _require_user(user_id, screen_name)
    user = _get_user(user_id, screen_name)
    raise Aclog::Exceptions::UserNotFound unless user
    raise Aclog::Exceptions::UserProtected.new(user) unless authorized_to_show_user?(user)
    user
  end
end

