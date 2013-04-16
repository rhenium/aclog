class UsersController < ApplicationController
  before_filter :force_page, :only => [:best, :recent]
  before_filter :require_user, :except => [:show, :favoriters]
  before_filter :include_user_b, :only => [:favorited_by, :retweeted_by, :given_favorites_to, :given_retweets_to]
  after_filter :check_protected

  def best
    @title = "@#{@user.screen_name}'s Best Tweets"

    render_timeline do
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

    render_timeline do
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
    @title = "@#{@user.screen_name}'s Newest Tweets"

    render_timeline do
      if get_bool(params[:all])
        @user.tweets.order_by_id
      else
        @user.tweets.reacted.order_by_id
      end
    end
  end

  def discovered
    @title = "@#{@user.screen_name}'s Recent Discoveries"

    render_timeline do
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

    @include_user_stats = true
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
    tweet_id = params[:id].to_i
    @item = Tweet.where(:id => tweet_id).first

    raise Aclog::Exceptions::TweetNotFound unless @item
    @user = @item.user

    # import 100
    if params[:import] == "force" && session[:account]
      session[:account].import_favorites(@item.id)
    end

    helpers = ApplicationController.helpers
    @title = "\"#{helpers.strip_tags(helpers.format_tweet_text(@item.text))[0...30]}\" from @#{@user.screen_name}"
    @title_b = "@#{@user.screen_name}'s Tweet"

    @full = get_bool(params[:full])
  end

  # only json
  def favoriters
    tweet_id = params[:id].to_i
    @item = Tweet.where(:id => tweet_id).first

    raise Aclog::Exceptions::TweetNotFound unless @item

    render json: @item.favorites.map{|f| f.user_id}
  end

  private
  def render_users_ranking
    by = -> model do
      model.joins(
        "INNER JOIN (" +
          "SELECT id FROM tweets WHERE tweets.user_id = #{@user.id} ORDER BY id DESC LIMIT 100" +
        ") target ON tweet_id = target.id")
    end

    to = -> model do
      Tweet.joins(
        "INNER JOIN (" +
          "SELECT tweet_id FROM #{model.table_name} WHERE #{model.table_name}.user_id = #{@user.id} ORDER BY id DESC LIMIT 500" +
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

    render "shared/users"
  end

  def render_user_to_user
    render_timeline do
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
    if params[:screen_name] == "me"
      if session[:user_id]
        params[:user_id] = session[:user_id]
      else
        raise Aclog::Exceptions::LoginRequired
      end
    end

    if params[:user_id]
      user = User.cached(params[:user_id].to_i)
    end

    if !user && params[:screen_name]
      user = User.cached(params[:screen_name])
    end

    raise Aclog::Exceptions::UserNotFound unless user

    @user = user
  end

  def include_user_b
    if params[:user_id_b]
      user_b = User.cached(params[:user_id_b].to_i)
    end

    if !user_b && params[:screen_name_b]
      user_b = User.where(:screen_name => params[:screen_name_b]).first
    end

    @user_b = user_b
  end

  def check_protected
    if @user && @user.protected? && !@user.registered?
      unless session[:account] && session[:account].user_id == @user.id
        raise Aclog::Exceptions::UserProtected if @user.protected
      end
    end
  end
end
