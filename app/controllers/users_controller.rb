class UsersController < ApplicationController
  def best
    user = render_timeline(params) do |tweets, user|
      tweets.of(user).reacted.order_by_reactions
    end
    @title = "@#{user.screen_name}'s Best Tweets"
  end

   def recent
    user = render_timeline(params) do |tweets, user|
      tweets.of(user).recent.reacted.order_by_reactions
    end
    @title = "@#{user.screen_name}'s Recent Best Tweets"
  end

  def timeline
    user = render_timeline(params) do |tweets, user|
      if params[:tweets] == "all"
        tweets.of(user).order_by_id
      else
        tweets.of(user).reacted.order_by_id
      end
    end
    @title = "@#{user.screen_name}'s Newest Tweets"

    if user.protected
      raise Exception # FIXME
    end
  end

  def discovered
    user = render_timeline(params) do |tweets, user|
      case params[:tweets]
      when "favorite"
        tweets.favorited_by(user).order_by_id
      when "retweet"
        tweets.retweeted_by(user).order_by_id
      else
        tweets.discovered_by(user).order_by_id
      end
    end
    @title = "@#{user.screen_name}'s Recent Discoveries"
  end

  private
  def render_timeline(params, &g)
    page = get_page_number(params)
    count = get_page_count(params)
    screen_name = params[:screen_name]
    user_id = params[:user_id]

    @user = User.where(:screen_name => screen_name).first
    unless @user
      @user = User.where(:id => user_id).first
      unless @user
        raise ActiveRecord::RecordNotFound.new("screen_name=#{screen_name}&user_id=#{user_id}")
      end
    end

    @items = g.call(Tweet, @user)
      .page(page)
      .per(count)

    respond_to do |format|
      format.html

      format.json do
        @include_user = params[:include_user] == "true"
      end
    end

    return @user
  end
end
