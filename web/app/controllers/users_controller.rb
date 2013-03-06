class UsersController < ApplicationController
  def best
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.find_by(:screen_name => screen_name)
    if user
      @items = user.tweets
        .where("favorites_count > 0 or retweets_count > 0")
        .order("COALESCE(favorites_count, 0) + COALESCE(retweets_count, 0) DESC")
        .paginate(:page => page, :per_page => Settings.page_per)
    else
      @items = []
    end
    @user_cache = get_user_cache(@items)
    @title = "Best tweets of #{screen_name} page #{page}"
  end

   def recent
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.find_by(:screen_name => screen_name)
    if user
      @items = user.tweets
        .where("favorites_count > 0 or retweets_count > 0")
        .order("id DESC")
        .paginate(:page => page, :per_page => Settings.page_per)
    else
      @items = []
    end
    @user_cache = get_user_cache(@items)
    @title = "Recent faved of #{screen_name} page #{page}"
  end

  def timeline
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.find_by(:screen_name => screen_name)
    if user
      @items = user.tweets
        .order("id DESC")
        .paginate(:page => page, :per_page => Settings.page_per)
    else
      @items = []
    end
    @user_cache = get_user_cache(@items)
    @title = "User timeline of #{screen_name} page #{page}"
  end

  def my
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.find_by(:screen_name => screen_name)
    if user
      tweet_ids = ActiveRecord::Base.connection.execute(
        "SELECT * FROM (" +
        "SELECT tweet_id FROM favorites WHERE user_id = #{user.id} " +
        "UNION " +
        "SELECT tweet_id FROM retweets WHERE user_id = #{user.id} " +
        ") rf " +
        "ORDER BY 1 DESC " +
        "LIMIT #{Settings.page_per} " +
        "OFFSET #{Settings.page_per * (page - 1)}")
      tweet_ids.map!{|m| m.values[0]}
      if tweet_ids && tweet_ids.size > 0
        @items = Tweet.find(tweet_ids, :order => "id DESC")
      else
        @items = []
      end
    else
      @items = []
    end
    @user_cache = get_user_cache(@items)
    @title = "Favs from #{screen_name} page #{page}"
  end

  def info
    screen_name = params[:screen_name]
    user = User.find_by(:screen_name => screen_name)
    if user && account = Account.find_by(:id => user.id)
      @info = get_user_info
    else
      @info = nil
    end
  end
end
