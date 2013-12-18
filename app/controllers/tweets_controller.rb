class TweetsController < ApplicationController
  def show
    @tweet = Tweet.find(params[:id])
    @user = @tweet.user
  rescue ActiveRecord::RecordNotFound
    raise Aclog::Exceptions::TweetNotFound
  end

  def lookup
    @tweets = Tweet.where(id: params[:id].to_s.split(",").map(&:to_i))
  end

  def index
    user_required
    begin
      best
    rescue
      timeline
      render "timeline"
    else
      render "best"
    end
  end

  def best
    user_required
    check_public!
    @tweets = @user.tweets.list(params, force_page: true).reacted.order_by_reactions
  end

  def recent
    user_required
    check_public!
    @tweets = @user.tweets.list(params, force_page: true).recent.reacted.order_by_reactions
  end

  def timeline
    user_required
    @tweets = @user.tweets.list(params).reacted.order_by_id
  end

  def discoveries
    user_required
    @tweets = Tweet.list(params, force_page: true).discovered_by(@user).order_by_id
  end

  def favorites
    user_required
    @tweets = Tweet.list(params, force_page: true).favorited_by(@user).order_by_id
  end

  def retweets
    user_required
    @tweets = Tweet.list(params, force_page: true).retweeted_by(@user).order_by_id
  end

  def discovered_by
    user_required
    user_b_required
    @tweets = @user.tweets.list(params).discovered_by(@user_b).order_by_id
  end

  def all_best
    @tweets = Tweet.list(params, force_page: true).reacted.order_by_reactions
  end

  def all_recent
    @tweets = Tweet.list(params, force_page: true).recent.reacted.order_by_reactions
  end

  def all_timeline
    @tweets = Tweet.list(params).reacted.order_by_id
  end

  def search
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
    if @tweets && request.xhr?
      html = render_to_string(partial: "tweet", collection: @tweets.includes(:user), as: :tweet, formats: :html)
      n = @tweets.length > 0 ?
          url_for(params[:page] ?
                  params.merge(page: params[:page].to_i + 1) :
                  params.merge(max_id: @tweets.last.id - 1)) :
          nil
      super json: {html: html, next: n}
    elsif @tweets && !lookup_context.exists?(params[:action], params[:controller]) && request.format == :json
      super("_tweets")
    else
      super(*args)
    end
  end

  def _require_user(user_id, screen_name)
    user = User.get(user_id, screen_name)
    raise Aclog::Exceptions::UserProtected.new(user) unless authorized_to_show_user?(user)
    user
  end
end

