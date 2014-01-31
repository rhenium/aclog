class TweetsController < ApplicationController
  param_group :pagination_with_page_number do
    optional :count, 5, "The number of tweets to retrieve. Must be less than or equal to #{Settings.tweets.count.max}, defaults to #{Settings.tweets.count.default}."
    optional :page, 2, "The page number of results to retrieve."
  end

  param_group :pagination_with_ids do
    param_group :pagination_with_page_number
    optional :since_id, 12345, "Returns results with an ID greater than the specified ID."
    optional :max_id, 54321, "Returns results with an ID less than or equal to the specified ID."
  end

  param_group :user do
    optional :user_id, 15926668, "The numerical ID of the user for whom to return results for."
    optional :screen_name, "toshi_a", "The username of the user for whom to return results for."
  end

  param_group :threshold do
    optional :reactions, 5, "Returns Tweets which has received reactions more than (or equal to) the specified number of times."
  end

  def index
    begin
      best
      render :best
    rescue Aclog::Exceptions::AccountPrivate
      timeline
      render :timeline
    end
  end

  get "tweets/show"
  description "Returns a single Tweet, specified by ID."
  requires :id, 43341783446466560, "The numerical ID of the desired Tweet."
  def show
    @tweet = Tweet.find(params[:id])
    @user = @tweet.user
    authorize_to_show_user! @user
  end

  get "tweets/lookup"
  description "Returns Tweets, specified by comma-separated IDs."
  requires :ids, "43341783446466560,50220624609685505", "A comma-separated list of Tweet IDs, up to #{Settings.tweets.count.max} are allowed in a single request."
  def lookup
    @tweets = Tweet.where(id: (params[:ids] || params[:id]).split(",").map(&:to_i))
  end

  get "tweets/best"
  description "Returns the best Tweets of a user, specified by username or user ID."
  param_group :user
  param_group :pagination_with_page_number
  def best
    @user = require_user
    authorize_to_show_user! @user
    authorize_to_show_user_best! @user
    @tweets = paginate_with_page_number(@user.tweets.reacted.order_by_reactions)
  end

  get "tweets/recent"
  nodoc
  description "Returns the best Tweets in the recent three days of a user, specified by username or user ID."
  param_group :user
  param_group :pagination_with_page_number
  def recent
    @user = require_user
    authorize_to_show_user! @user
    authorize_to_show_user_best! @user
    @tweets = paginate_with_page_number(@user.tweets.reacted.recent.order_by_reactions)
  end

  get "tweets/timeline"
  description "Returns the newest Tweets of a user, specified by username or user ID."
  param_group :user
  param_group :pagination_with_ids
  param_group :threshold
  def timeline
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(@user.tweets.reacted(params[:reactions]).order_by_id)
  end

  get "tweets/discoveries"
  description "Returns the Tweets which a user specified by username or user ID discovered."
  param_group :user
  param_group :pagination_with_ids
  def discoveries
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(Tweet).discovered_by(@user).order_by_id
  end

  get "tweets/favorites"
  nodoc
  description "Returns the Tweets which a user specified by username or user ID favorited."
  param_group :user
  param_group :pagination_with_ids
  def favorites
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(Tweet).favorited_by(@user).order_by_id
  end

  get "tweets/retweets"
  nodoc
  description "Returns the Tweets which a user specified by username or user ID retweeted."
  param_group :user
  param_group :pagination_with_ids
  def retweets
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(Tweet).retweeted_by(@user).order_by_id
  end

  get "tweets/discovered_by"
  description "Returns the Tweets which a user specified by username or user ID retweeted."
  param_group :user
  optional :user_id_b, 280414022, "The numerical ID of the subject user."
  optional :screen_name_b, "cn", "The username of the subject user."
  param_group :pagination_with_ids
  def discovered_by
    @user = require_user
    authorize_to_show_user! @user
    @source_user = User.find(id: params[:user_id_b], screen_name: params[:screen_name_b])
    authorize_to_show_user! @source_user
    @tweets = paginate(@user.tweets.discovered_by(@source_user).order_by_id)
  end

  get "tweets/all_best"
  nodoc
  param_group :pagination_with_page_number
  def all_best
    @tweets = paginate_with_page_number(Tweet.reacted.order_by_reactions)
  end

  get "tweets/all_recent"
  nodoc
  param_group :pagination_with_page_number
  def all_recent
    @tweets = paginate_with_page_number(Tweet.recent.reacted.order_by_reactions)
  end

  get "tweets/all_timeline"
  nodoc
  param_group :pagination_with_ids
  param_group :threshold
  def all_timeline
    @tweets = paginate(Tweet.reacted(params[:reactions]).order_by_id)
  end

  get "tweets/filter"
  nodoc
  param_group :pagination_with_ids
  def filter
    @tweets = paginate(Tweet.reacted.recent(7).filter_by_query(params[:q].to_s).not_protected.order_by_id)
  end

  get "tweets/import"
  nodoc
  requires :id, 43341783446466560, "The numerical ID of the desired Tweet."
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
    if !request.xhr? && request.format == :json
      # JSON API / Atom
      begin
        super(*args)
      rescue ActionView::MissingTemplate
        if @tweets
          super("_tweets")
        elsif @tweet
          super("_tweet")
        else
          raise
        end
      end
    else
      if @tweets && request.xhr?
        super(json: { html: render_to_string(partial: "tweet", collection: @tweets, as: :tweet, formats: :html),
                      next_url: @next_url,
                      prev_url: @prev_url })
      else
        super(*args)
      end
    end
  end
end

