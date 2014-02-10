class TweetsController < ApplicationController
  def index
    begin
      best
      render :best
    rescue Aclog::Exceptions::AccountPrivate
      timeline
      render :timeline
    end
  end

  def show
    @tweet = Tweet.find(params[:id])
    @user = @tweet.user
    authorize_to_show_user! @user
    @replies_before = @tweet.reply_ancestors(2)
    @replies_after = @tweet.reply_descendants(2)
  end

  def best
    @user = require_user
    authorize_to_show_user! @user
    authorize_to_show_user_best! @user
    @tweets = paginate_with_page_number(@user.tweets.reacted.order_by_reactions)
  end

  def recent
    @user = require_user
    authorize_to_show_user! @user
    authorize_to_show_user_best! @user
    @tweets = paginate_with_page_number(@user.tweets.reacted.recent.order_by_reactions)
  end

  def timeline
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(@user.tweets.reacted(params[:reactions]).order_by_id)
  end

  def discoveries
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(Tweet).discovered_by(@user).order_by_id
  end

  def favorites
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(Tweet).favorited_by(@user).order_by_id
  end

  def retweets
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(Tweet).retweeted_by(@user).order_by_id
  end

  def discovered_by
    @user = require_user
    authorize_to_show_user! @user
    @source_user = User.find(id: params[:user_id_b], screen_name: params[:screen_name_b])
    authorize_to_show_user! @source_user
    @tweets = paginate(@user.tweets).discovered_by(@source_user).order_by_id
  end

  def all_best
    @tweets = paginate_with_page_number(Tweet.reacted.order_by_reactions)
  end

  def all_recent
    @tweets = paginate_with_page_number(Tweet.recent.reacted.order_by_reactions)
  end

  def all_timeline
    @tweets = paginate(Tweet.reacted(params[:reactions]).order_by_id)
  end

  def filter
    @tweets = paginate(Tweet.reacted.recent(7).filter_by_query(params[:q].to_s).not_protected.order_by_id)
  end

  def import
    raise Aclog::Exceptions::LoginRequired unless logged_in?
    tweet = current_user.account.import(params[:id])
    redirect_to tweet
  end

  private
  def require_user
    User.find(id: params[:user_id], screen_name: params[:screen_name])
  end

  def paginate(tweets)
    if params[:page]
      paginate_with_page_number(tweets)
    else
      tweets = tweets.limit(params_count).max_id(params[:max_id]).since_id(params[:since_id])
      if tweets.length > 0
        @prev_url = url_for(params.tap {|h| h.delete(:max_id) }.merge(since_id: tweets.first.id))
        @next_url = url_for(params.tap {|h| h.delete(:since_id) }.merge(max_id: tweets.last.id - 1))
      end
      tweets
    end
  end

  def paginate_with_page_number(tweets)
    page = (params[:page] || 1).to_i
    @prev_url = page == 1 ? nil : url_for(params.merge(page: page - 1))
    @next_url = url_for(params.merge(page: page + 1))
    tweets.limit(params_count).page(page)
  end

  def params_count
    [(params[:count] || Settings.tweets.count.default).to_i, Settings.tweets.count.max].min
  end

  def render(*args)
    if @tweets && request.xhr?
      super(json: { html: render_to_string(partial: "tweet", collection: @tweets, as: :tweet, formats: :html),
                    next_url: @next_url,
                    prev_url: @prev_url })
    else
      super(*args)
    end
  end
end

