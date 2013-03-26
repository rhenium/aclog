class UsersController < ApplicationController
  before_filter :get_user

  def best
    @title = "@#{@user.screen_name}'s Best Tweets"
    render_page do
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
    render_page do
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
    raise Exception.new if @user.protected #FIXME

    @title = "@#{@user.screen_name}'s Newest Tweets"
    render_page do
      case params[:tweets]
      when /^all/
        @user.tweets.order_by_id
      else
        @user.tweets.reacted.order_by_id
      end
    end
  end

  def discovered
    @title = "@#{@user.screen_name}'s Recent Discoveries"
    render_page do
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
    account = Account.where(:user_id => @user.id).first
    unless account
      raise ActiveRecord::RecordNotFound.new("Account not found: #{@user}")
    end

    @title = "@#{@user.screen_name} (#{@user.name})'s Profile"

    @twitter_user = account.twitter_user

    respond_to do |format|
      format.html
      format.json
    end
  end

  def from
    hash = {}
    @user.tweets.order_by_id.limit(100).each do |tweet|
      case params[:event]
      when /^fav/
        events = tweet.favorites
      when /^re?t/
        events = tweet.retweets
      else
        raise Exception.new("Invalid event type")
      end

      events.each do |event|
        hash[event.user_id] ||= 0
        hash[event.user_id] += 1
      end
    end

    @usermap = hash.sort_by{|id, count| -count}
      .take(50)
      .map{|user, count| [User.cached(user), count]}
  end

  private
  def render_page(&blk)
    @items = blk.call.page(page).per(count)

    respond_to do |format|
      format.html
      format.json
    end
  end

  def get_user
    if params[:user_id]
      @user = User.cached(params[:user_id].to_i)
    end

    if !@user || params[:screen_name]
      @user = User.where(:screen_name => params[:screen_name]).first
    end

    unless @user
      raise ActiveRecord::RecordNotFound.new(
        "User not found: #{{:user_id => params[:user_id], :screen_name => params[:screen_name]}.inspect}")
    end
  end

  def page
    if params[:page]
      i = params[:page].to_i
      if i > 0
        ret = i
      end
    end
    ret || 1
  end

  def count
    if params[:count]
      i = params[:count].to_i
      if (1..100) === i
        ret = i
      end
    end
    ret || Settings.page_per
  end

  def include_user
    case params[:include_user]
    when /^t/
      ret = true
    end
    ret || false
  end
end
