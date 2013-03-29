class UsersController < ApplicationController
  before_filter :get_user, :except => :show
  before_filter :get_user_b

  def best
    @title = "@#{@user.screen_name}'s Best Tweets"
    render_tweets do
      case order
      when :favorite
        @user.tweets.reacted.order_by_favorites
      when :retweet
        @user.tweets.reacted.order_by_retweets
      else
        @user.tweets.reacted.order_by_reactions
      end
    end
  end

   def recent
    @title = "@#{@user.screen_name}'s Recent Best Tweets"
    render_tweets do
      case order
      when :favorite
        @user.tweets.recent.reacted.order_by_favorites
      when :retweet
        @user.tweets.recent.reacted.order_by_retweets
      else
        @user.tweets.recent.reacted.order_by_reactions
      end
    end
  end

  def timeline
    raise Aclog::Exceptions::UserProtected if @user.protected

    @title = "@#{@user.screen_name}'s Newest Tweets"
    render_tweets do
      if all
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
    raise Aclog::Exceptions::UserNotRegistered unless @user.account

    @title = "@#{@user.screen_name} (#{@user.name})'s Profile"

    respond_to do |format|
      format.html
      format.json do
        @include_user_stats = true
      end
    end
  end

  def favorited_by
    if @user_b
      @title = "@#{@user.screen_name}'s Tweets"
      render_tweets(@user.tweets.favorited_by(@user_b).order_by_id)
    else
      @title = "Who Favorited @#{@user.screen_name}"
      @event_type = "favs"
      render_users_by(:favorite)
    end
  end

  def retweeted_by
    if @user_b
      @title = "@#{@user.screen_name}'s Tweets"
      render_tweets(@user.tweets.retweeted_by(@user_b).order_by_id)
    else
      @title = "Who Retweeted @#{@user.screen_name}"
      @event_type = "retweets"
      render_users_by(:retweet)
    end
  end

  def given_favorites_to
    if @user_b
      @title = "@#{@user_b.screen_name}'s Tweets"
      render_tweets(@user_b.tweets.favorited_by(@user).order_by_id)
    else
      @title = "@#{@user.screen_name}'s Favorites"
      @event_type = "favs"
      render_users_to(:favorite)
    end
  end

  def given_retweets_to
    if @user_b
      @title = "@#{@user_b.screen_name}'s Tweets"
      render_tweets(@user_b.tweets.retweeted_by(@user).order_by_id)
    else
      @title = "@#{@user.screen_name}'s Retweets"
      @event_type = "retweets"
      render_users_to(:retweet)
    end
  end

  def show
    tweet_id = params[:id].to_i
    @items = Tweet.where(:id => tweet_id).page

    item = @items.first
    raise Aclog::Exceptions::TweetNotFound unless item
    @user = item.user

    helpers = ApplicationController.helpers
    @title = "\"#{helpers.strip_tags(helpers.format_tweet_text(item.text))[0...30]}\" from @#{@user.screen_name}"
    @title_b = "@#{@user.screen_name}'s Tweet"

    respond_to do |format|
      format.html do
        render "shared/tweets"
      end
      format.json do
        render "shared/_tweet", :locals => {:item => item}
      end
    end
  end

  private
  def render_users_by(event)
    case event
    when :favorite
      pr = -> tweet{tweet.favorites}
    when :retweet
      pr = -> tweet{tweet.retweets}
    end

    @usermap = @user.tweets
      .order_by_id
      .limit(100)
      .inject(Hash.new(0)){|hash, tweet| pr.call(tweet).each{|event| hash[event.user_id] += 1}; hash}
      .sort_by{|id, count| -count}

    render "shared/users"
  end

  def render_users_to(event)
    case event
    when :favorite
      es = @user.favorites
    when :retweet
      es = @user.retweets
    end

    @usermap = es
      .order_by_id
      .limit(500)
      .map{|e| Tweet.cached(e.tweet_id)}
      .compact
      .inject(Hash.new(0)){|hash, tweet| hash[tweet.user_id] += 1; hash}
      .sort_by{|user_id, count| -count}

    render "shared/users"
  end

  def get_user
    if params[:screen_name] == "me"
      if session[:user_id]
        params[:user_id] = session[:user_id]
      else
        raise Aclog::Exceptions::LoginRequired
      end
    end

    if params[:user_id]
      #@user = User.cached(params[:user_id].to_i)
      @user = User.cached(params[:user_id].to_i)
    end

    if !@user && params[:screen_name]
      #@user = User.where(:screen_name => params[:screen_name]).first
      @user = User.cached(params[:screen_name])
    end

    raise Aclog::Exceptions::UserNotFound unless @user
    raise Aclog::Exceptions::UserNotRegistered if @user.protected? && !@user.registered?
  end

  def get_user_b
    if params[:screen_name_b] == "me"
      if session[:user_id]
        params[:user_id_b] = session[:user_id]
      else
        raise Aclog::Exceptions::LoginRequired
      end
    end

    if params[:user_id_b]
      @user_b = User.cached(params[:user_id_b].to_i)
    end

    if !@user_b && params[:screen_name_b]
      @user_b = User.where(:screen_name => params[:screen_name_b]).first
    end
  end
end
