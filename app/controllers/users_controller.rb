class UsersController < ApplicationController
  before_filter :require_user, except: [:show, :favoriters]
  before_filter :require_tweet, only: [:show, :favoriters]
  before_filter :include_user_b, only: [:favorited_by, :retweeted_by, :given_favorites_to, :given_retweets_to]
  after_filter :check_protected

  def best
    @title = "@#{@user.screen_name}'s Best Tweets"

    render_tweets(force_page: true) do
      case params[:order]
      when /^fav/
        @user.tweets.reacted.order_by_favorites
      when /^re?t/
        @user.tweets.reacted.order_by_retweets
      else
        @user.tweets.reacted.order_by_reactions
      end
    end
  end

  def recent
    @title = "@#{@user.screen_name}'s Recent Best Tweets"

    render_tweets(force_page: true) do
      case params[:order]
      when /^fav/
        @user.tweets.recent.reacted.order_by_favorites
      when /^re?t/
        @user.tweets.recent.reacted.order_by_retweets
      else
        @user.tweets.recent.reacted.order_by_reactions
      end
    end
  end

  def timeline
    @title = "@#{@user.screen_name}'s Newest Tweets"

    render_tweets do
      if !!params[:all]
        @user.tweets.order_by_id
      else
        @user.tweets.reacted.order_by_id
      end
    end
  end

  def discovered
    @title = "@#{@user.screen_name}'s Recent Discoveries"

    render_tweets do
      case params[:tweets]
      when /^fav/
        Tweet.favorited_by(@user).order_by_id
      when /^re?t/
        Tweet.retweeted_by(@user).order_by_id
      else
        Tweet.discovered_by(@user).order_by_id
      end
    end
  end

  def info
    raise Aclog::Exceptions::UserNotRegistered unless @user.registered?

    @title = "@#{@user.screen_name} (#{@user.name})'s Profile"
  end

  def favorited_by
    if @user_b
      render_user_to_user
    else
      render_users_ranking
    end
  end

  def retweeted_by
    if @user_b
      render_user_to_user
    else
      render_users_ranking
    end
  end

  def given_favorites_to
    if @user_b
      render_user_to_user
    else
      render_users_ranking
    end
  end

  def given_retweets_to
    if @user_b
      render_user_to_user
    else
      render_users_ranking
    end
  end

  def show
    @user = @item.user

    # import 100
    if params[:import] == "force" && session[:account]
      session[:account].import_favorites(@item.id)
    end

    text = ApplicationController.helpers.format_tweet_text(@item.text)[0...30]
    @title = "\"#{text}\" from @#{@user.screen_name}"
    @title_b = "@#{@user.screen_name}'s Tweet"
  end

  # only json
  def favoriters
    render json: @item.favorites.load.map{|f| f.user_id}
  end

  private
  def render_users_ranking
    by = -> model do
      model.joins(
        "INNER JOIN (#{@user.tweets.order_by_id.limit(100).to_sql}) target ON tweet_id = target.id")
    end

    to = -> model do
      Tweet.joins(
        "INNER JOIN (" +
          model.where(user_id: @user.id).order("id DESC").limit(500).to_sql +
        ") action ON tweets.id = action.tweet_id")
    end

    case params[:action].to_sym
    when :favorited_by
      @title = "Who Favorited @#{@user.screen_name}"
      users_object = by.call(Favorite)
    when :retweeted_by
      @title = "Who Retweeted @#{@user.screen_name}"
      users_object = by.call(Retweet)
    when :given_favorites_to
      @title = "@#{@user.screen_name}'s Favorites"
      users_object = to.call(Favorite)
    when :given_retweets_to
      @title = "@#{@user.screen_name}'s Retweets"
      users_object = to.call(Retweet)
    end

    @usermap = users_object
      .inject(Hash.new(0)){|hash, obj| hash[obj.user_id] += 1; hash}
      .sort_by{|id, count| -count}

    render "shared/user_ranking"
  end

  def render_user_to_user
    render_tweets do
      case params[:action].to_sym
      when :favorited_by
        @title = "@#{@user.screen_name}'s Tweets"
        @user.tweets.favorited_by(@user_b).order_by_id
      when :retweeted_by
        @title = "@#{@user.screen_name}'s Tweets"
        @user.tweets.retweeted_by(@user_b).order_by_id
      when :given_favorites_to
        @title = "@#{@user_b.screen_name}'s Tweets"
        @user_b.tweets.favorited_by(@user).order_by_id
      when :given_retweets_to
        @title = "@#{@user_b.screen_name}'s Tweets"
        @user_b.tweets.retweeted_by(@user).order_by_id
      end
    end
  end

  def require_user
    user = User.where(id: params[:user_id]).first || User.where(screen_name: params[:screen_name]).first
    raise Aclog::Exceptions::UserNotFound unless user
    @user = user
  end

  def include_user_b
    user_b = User.where(id: params[:user_id_b]).first || User.where(screen_name: params[:screen_name_b]).first
    @user_b = user_b
  end

  def require_tweet
    item = Tweet.where(id: params[:id]).first
    raise Aclog::Exceptions::TweetNotFound unless item
    @item = item
  end

  def check_protected
    if @user && @user.protected?
      if session[:account] == nil || session[:account].user_id != @user.id
        raise Aclog::Exceptions::UserProtected
      end
    end
  end
end
