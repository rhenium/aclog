class UsersController < ApplicationController
  def best
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.where(:screen_name => screen_name).first
    if user
      @items = user.tweets
        .where("favorites_count > 0 OR retweets_count > 0")
        .order("COALESCE(favorites_count, 0) + COALESCE(retweets_count, 0) DESC")
        .page(page)
        .per(Settings.page_per)
    else
      @items = []
    end
    @title = "@#{screen_name}'s Best Tweets"
  end

   def recent
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.where(:screen_name => screen_name).first
    if user
      @items = user.tweets
        .where("favorites_count > 0 OR retweets_count > 0")
        .order("id DESC")
        .page(page)
        .per(Settings.page_per)
    else
      @items = []
    end
    @title = "@#{screen_name}'s Newest Favorited Tweets"
  end

  def timeline
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.where(:screen_name => screen_name).first
    if user
      @items = user.tweets
        .order("id DESC")
        .page(page)
        .per(Settings.page_per)
    else
      @items = []
    end
    @title = "@#{screen_name}'s Newest Tweets"
  end

  def my
    page = get_page_number(params)
    screen_name = params[:screen_name]
    user = User.where(:screen_name => screen_name).first
    if user
      @items = Tweet
        .where("id IN (SELECT tweet_id FROM (" +
          "SELECT tweet_id FROM favorites WHERE user_id = #{user.id} " +
          "UNION " +
          "SELECT tweet_id FROM retweets WHERE user_id = #{user.id}" +
          ") AS rf)")
        .order("id DESC")
        .page(page)
        .per(Settings.page_per)

    else
      @items = []
    end
    @title = "@#{screen_name}'s Recent Discoveries"
    prepare_cache
  end

  def info
    screen_name = params[:screen_name]
    user = User.where(:screen_name => screen_name).first
    if user
      @tweets_count = user.tweets.count
      @favorites_count = user.favorites.count
      @retweets_count = user.retweets.count
      @favorited_count = user.tweets.inject(0){|s, m| s + m.favorites_count}
      @retweeted_count = user.tweets.inject(0){|s, m| s + m.retweets_count}
    else
      @info = nil
    end
  end
end
