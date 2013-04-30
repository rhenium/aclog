class TweetsController < ApplicationController
  # GET /i/:id
  # GET /api/tweets/show
  def show
    tweet_required
    @user = @tweet.user

    @description = "#{@user.screen_name}'s Tweet"
    text = ApplicationController.helpers.format_tweet_text(@tweet.text)[0...30]
    @title = "\"#{text}\" from #{@user.screen_name}"
  end

  # GET /:screen_name
  # GET /i/best
  # GET /api/tweets/best
  def best
    user_optional
    @description = "Best"
    @tweets = Tweet.of(@user).reacted.order_by_reactions.list(params, force_page: true)
  end

  # GET /:screen_name/favorited
  # GET /api/tweets/favorited
  def favorited
    user_optional
    @description = "Most Favorited"
    @tweets = Tweet.of(@user).reacted.order_by_favorites.list(params, force_page: true)
  end

  # GET /:screen_name/retweeted
  # GET /api/tweets/retweeted
  def retweeted
    user_optional
    @description = "Most Retweeted"
    @tweets = Tweet.of(@user).reacted.order_by_retweets.list(params, force_page: true)
  end

  # GET /i/recent
  # GET /api/tweets/recent
  def recent
    user_optional
    @description = "Recent Best"
    @tweets = Tweet.of(@user).recent.reacted.order_by_reactions.list(params, force_page: true)
  end

  # GET /:screen_name/timeline
  # GET /i/timeline
  # GET /api/tweets/timeline
  def timeline
    user_optional
    @description = "Recent"
    @tweets = Tweet.of(@user).reacted.order_by_id.list(params)
  end

  # GET /:screen_name/discoveries
  # GET /api/tweets/discoveries
  def discoveries
    user_required
    @description = "Discoveries"
    @tweets = Tweet.discovered_by(@user).order_by_id.list(params)
  end

  # GET /:screen_name/favorites
  # GET /api/tweets/favorites
  def favorites
    user_required
    @description = "Favorites"
    @tweets = Tweet.favorited_by(@user).order_by_id.list(params)
  end

  # GET /:screen_name/retweets
  # GET /api/tweets/retweets
  def retweets
    user_required
    @description = "Retweets"
    @tweets = Tweet.retweeted_by(@user).order_by_id.list(params)
  end

  # GET /:screen_name/discovered_by/:screen_name_b
  # GET /api/tweets/discovered_by
  def discovered_by
    user_required
    user_b_required
    @description = "Discovored by #{@user_b.screen_name}"
    @tweets = Tweet.of(@user).discovered_by(@user_b).order_by_id.list(params)
  end

  private
  def render(*args)
    if args.empty?
      if params[:action] == "show"
        super "shared/tweet"
      else
        super "shared/tweets"
      end
    else
      super(*args)
    end
  end

  def user_optional
    @user = _get_user(params[:user_id], params[:screen_name])
  end

  def user_required
    user_optional
    raise Aclog::Exceptions::UserNotFound unless @user
  end

  def user_b_required
    @user_b = _get_user(params[:user_id_b], params[:screen_name_b])
    raise Aclog::Exceptions::UserNotFound unless @user_b
  end
end
