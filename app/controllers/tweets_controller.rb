# -*- encoding: utf-8 -*-
class TweetsController < ApplicationController
  before_filter :set_user_limit

  # GET /i/:id
  # GET /api/tweets/show
  def show
    tweet_required

    @caption = "#{@user.screen_name}'s Tweet"
    text = ApplicationController.helpers.format_tweet_text(@tweet.text)
    @title = "\"#{text}\" from #{@user.screen_name}"
  end

  # GET /:screen_name
  # GET /i/best
  # GET /api/tweets/best
  def best
    user_optional
    @caption = "Best"
    @tweets = Tweet.of(@user).reacted.order_by_reactions.list(params, force_page: true)
  end

  # GET /:screen_name/favorited
  # GET /api/tweets/favorited
  def favorited
    user_optional
    @caption = "Most Favorited"
    @tweets = Tweet.of(@user).reacted.order_by_favorites.list(params, force_page: true)
  end

  # GET /:screen_name/retweeted
  # GET /api/tweets/retweeted
  def retweeted
    user_optional
    @caption = "Most Retweeted"
    @tweets = Tweet.of(@user).reacted.order_by_retweets.list(params, force_page: true)
  end

  # GET /i/recent
  # GET /api/tweets/recent
  def recent
    user_optional
    @caption = "Recent Best"
    @tweets = Tweet.of(@user).recent.reacted.order_by_reactions.list(params, force_page: true)
  end

  # GET /:screen_name/timeline
  # GET /i/timeline
  # GET /api/tweets/timeline
  def timeline
    user_optional
    @caption = "Recent"
    @tweets = Tweet.of(@user).reacted.order_by_id.list(params)
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
    @tweets = Tweet.of(@user).discovered_by(@user_b).order_by_id.list(params)
  end

  private
  def render(*args)
    if lookup_context.exists?(params[:action], params[:controller])
      super(*args)
    else
      super("_tweets")
    end
  end

  def user_optional
    @user = _get_user(params[:user_id], params[:screen_name])
    raise Aclog::Exceptions::UserProtected if @user and not authorized_to_show?(@user)
  end

  def user_required
    user_optional
    raise Aclog::Exceptions::UserNotFound unless @user
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
        @user_limit = 100
      end
    else
      @user_limit = 20
    end

    if request.format == :json
      @user_limit = nil
      # old api
      if params[:limit]
        @user_limit = params[:limit].to_i
      end
    end
  end
end
