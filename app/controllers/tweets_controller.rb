# -*- encoding: utf-8 -*-
class TweetsController < ApplicationController
  def show
    @tweets = Tweet.where(id: params[:id])
    raise Aclog::Exceptions::TweetNotFound unless @tweets.first
    @user = @tweets.first.user
    @caption = "#{@user.screen_name}'s Tweet"
  end

  # only JSON API
  def lookup
    ids = params[:id].to_s.split(",").map(&:to_i)
    @tweets = Tweet.where(id: ids)
    @caption = "Tweets"
  end

  def index
    user_required
    best rescue timeline
  end

  def best
    user_required
    check_public!
    @caption = "#{@user.screen_name}'s Best"
    @tweets = @user.tweets.list(params, force_page: true).reacted.order_by_reactions
  end

  def recent
    user_required
    check_public!
    @caption = "#{@user.screen_name}'s Recent Best"
    @tweets = @user.tweets.list(params, force_page: true).recent.reacted.order_by_reactions
  end

  def timeline
    user_required
    @caption = "#{@user.screen_name}'s Newest"
    @tweets = @user.tweets.list(params).reacted.order_by_id
  end

  def discoveries
    user_required
    @caption = "#{@user.screen_name}'s Discoveries"
    @tweets = Tweet.list(params, force_page: true).discovered_by(@user).order_by_id
  end

  def favorites
    user_required
    @caption = "#{@user.screen_name}'s Favorites"
    @tweets = Tweet.list(params, force_page: true).favorited_by(@user).order_by_id
  end

  def retweets
    user_required
    @caption = "#{@user.screen_name}'s Retweets"
    @tweets = Tweet.list(params, force_page: true).retweeted_by(@user).order_by_id
  end

  def discovered_by
    user_required
    user_b_required
    @caption = "Discovored by #{@user_b.screen_name}"
    @tweets = @user.tweets.list(params).discovered_by(@user_b).order_by_id
  end

  def all_best
    @caption = "Top Tweets"
    @tweets = Tweet.list(params, force_page: true).reacted.order_by_reactions
  end

  def all_recent
    @caption = "Recent"
    @tweets = Tweet.list(params, force_page: true).recent.reacted.order_by_reactions
  end

  def all_timeline
    @caption = "Newest"
    @tweets = Tweet.list(params).reacted.order_by_id
  end

  def search
    @caption = "Search"
    @tweets = Tweet.list(params, force_page: true).parse_query(params[:q].to_s || "").reacted.not_protected.order_by_id
    @tweets = @tweets.recent(7) unless @tweets.to_sql.include?("`tweets`.`id`")
  end

  private
  def user_required
    @user = _require_user(params[:user_id], params[:screen_name])
  end

  def user_b_required
    @user_b = _require_user(params[:user_id_b], params[:screen_name_b])
  end

  def check_public!
    authorize_to_show_best!(@user)
  end

  def render(*args)
    if request.xhr?
      html = render_to_string(partial: "tweets/tweet", collection: @tweets.includes(:user), as: :tweet, formats: :html)
      n = @tweets.length > 0 ?
          url_for(params[:page] ?
                  params.merge(page: params[:page].to_i + 1) :
                  params.merge(max_id: @tweets.last.id - 1)) :
          nil
      super json: {html: html, next: n}
    elsif lookup_context.exists?(params[:action], params[:controller])
      super(*args)
    else
      super("_tweets")
    end
  end

  def _require_user(user_id, screen_name)
    user = User.get(user_id, screen_name)
    raise Aclog::Exceptions::UserProtected.new(user) unless authorized_to_show_user?(user)
    user
  end
end

