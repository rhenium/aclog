# -*- encoding: utf-8 -*-
class TweetsController < ApplicationController
  before_filter :set_user_limit

  # GET /i/:id
  # GET /api/tweets/show
  def show
    tweet_required

    @caption = "#{@user.screen_name}'s Tweet"
    h = ApplicationController.helpers
    text = h.strip_tags(h.format_tweet_text(@tweet.text))
    @title = "\"#{text}\" from #{@user.screen_name}"
  end

  # GET /:screen_name
  # GET /api/tweets/best
  def best
    user_required
    @caption = "Best"
    @tweets = cache_tweets(3.minutes, @user.tweets.reacted.order_by_reactions.list(params, force_page: true))
  end

  # GET /:screen_name/favorited
  # GET /api/tweets/favorited
  def favorited
    user_required
    @caption = "Most Favorited"
    @tweets = cache_tweets(3.minutes, @user.tweets.reacted.order_by_favorites.list(params, force_page: true))
  end

  # GET /:screen_name/retweeted
  # GET /api/tweets/retweeted
  def retweeted
    user_required
    @caption = "Most Retweeted"
    @tweets = cache_tweets(3.minutes, @user.tweets.reacted.order_by_retweets.list(params, force_page: true))
  end

  # GET /api/tweets/recent
  def recent
    user_required
    @caption = "Recent Best"
    @tweets = cache_tweets(3.minutes, @user.tweets.recent.reacted.order_by_reactions.list(params, force_page: true))
  end

  # GET /:screen_name/timeline
  # GET /api/tweets/timeline
  def timeline
    user_required
    @caption = "Newest"
    @tweets = @user.tweets.reacted.order_by_id.list(params)
  end

  # GET /:screen_name/discoveries
  # GET /api/tweets/discoveries
  def discoveries
    user_required
    @caption = "Discoveries"
    @tweets = Tweet.discovered_by(@user).order_by_id.list(params)
  end

  # GET /:screen_name/favorites
  # GET /api/tweets/favorites
  def favorites
    user_required
    @caption = "Favorites"
    @tweets = Tweet.favorited_by(@user).order_by_id.list(params)
  end

  # GET /:screen_name/retweets
  # GET /api/tweets/retweets
  def retweets
    user_required
    @caption = "Retweets"
    @tweets = Tweet.retweeted_by(@user).order_by_id.list(params)
  end

  # GET /:screen_name/discovered_by/:screen_name_b
  # GET /api/tweets/discovered_by
  def discovered_by
    user_required
    user_b_required
    @caption = "Discovored by #{@user_b.screen_name}"
    @tweets = @user.tweets.discovered_by(@user_b).order_by_id.list(params)
  end

  # GET /i/best
  def all_best
    @caption = "Best of all"
    @tweets = cache_tweets(3.hours, Tweet.reacted.order_by_reactions.list(params, force_page: true))
  end

  # GET /i/recent
  def all_recent
    @caption = "Recent of all"
    @tweets = cache_tweets(10.minutes, Tweet.recent.reacted.order_by_reactions.list(params, force_page: true))
  end

  # GET /i/timeline
  def all_timeline
    @caption = "Newest of all"
    @tweets = Tweet.reacted.order_by_id.list(params)
  end

  private
  def render(*args)
    if lookup_context.exists?(params[:action], params[:controller])
      super(*args)
    else
      super("_tweets")
    end
  end

  def user_required
    @user = _get_user(params[:user_id], params[:screen_name])
    raise Aclog::Exceptions::UserNotFound unless @user
    raise Aclog::Exceptions::UserProtected unless authorized_to_show?(@user)
  end

  def user_b_required
    @user_b = _get_user(params[:user_id_b], params[:screen_name_b])
    raise Aclog::Exceptions::UserNotFound unless @user_b
    raise Aclog::Exceptions::UserProtected unless authorized_to_show?(@user)
  end

  def tweet_required
    @tweet = Tweet.find_by(id: params[:id])
    raise Aclog::Exceptions::TweetNotFound unless @tweet
    @user = @tweet.user
    raise Aclog::Exceptions::UserProtected unless authorized_to_show?(@user)
  end

  def set_user_limit
    if params[:action] == "show"
      if params[:full] == "true"
        @user_limit = nil
      else
        @user_limit = Settings.tweets.users.count_lot
      end
    else
      @user_limit = Settings.tweets.users.count_default
    end

    if request.format == :json
      if params[:limit]
        @user_limit = params[:limit].to_i
      else
        @user_limit = nil
      end
    end
  end

  def cache_tweets(expires_in, tweets)
    key = "tweets/#{params.to_param}"
    p ids = Rails.cache.read(key)
    if not ids
      Rails.cache.write(key, tweets.map(&:id), expires_in: expires_in)
      tweets
    else
      n = Tweet.where("id IN (?)", ids).order("CASE #{ids.each_with_index.map {|m, i| "WHEN ID = #{m} THEN #{i}" }.join(" ")} END")
    end
  end
end

