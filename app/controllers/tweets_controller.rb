class TweetsController < ApplicationController
  param_group :pagination_with_page_number do
    optional :count, :integer, "The number of tweets to retrieve. Must be less than or equal to 200, defaults to 20."
    optional :page, :integer, "The page number of results to retrieve."
  end

  param_group :pagination_with_ids do
    param_group :pagination_with_page_number
    optional :since_id, :integer, "Returns results with an ID greater than the specified ID."
    optional :max_id, :integer, "Returns results with an ID less than or equal to the specified ID."
  end

  param_group :user do
    optional :user_id, :integer, "The numerical ID of the user for whom to return results for."
    optional :screen_name, :string, "The username of the user for whom to return results for."
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
  requires :id, :integer, "The numerical ID of the desired Tweet."
  see "tweets#lookup"
  def show
    @tweet = Tweet.find(params[:id])
    @user = require_user(user_id: @tweet.user_id)
  end

  get "tweets/lookup"
  description "Returns Tweets, specified by comma-separated IDs."
  requires :id, /^\d+(,\d+)*,?$/, "A comma-separated list of Tweet IDs, up to #{Settings.tweets.count.max} are allowed in a single request."
  see "tweets#show"
  def lookup
    @tweets = Tweet.where(id: params[:id].split(",").map(&:to_i))
  end

  get "tweets/best"
  description "Returns the best Tweets of a user, specified by username or user ID."
  param_group :user
  param_group :pagination_with_page_number
  def best
    @user = require_user(public: true)
    @tweets = paginate_with_page_number(@user.tweets.reacted.order_by_reactions)
  end

  # get "tweets/recent"
  # description "Returns the best Tweets in the recent three days of a user, specified by username or user ID."
  # param_group :user
  # param_group :pagination_with_page_number
  def recent
    @user = require_user(public: true)
    @tweets = paginate_with_page_number(@user.tweets.reacted.recent.order_by_reactions)
  end

  get "tweets/timeline"
  description "Returns the newest Tweets of a user, specified by username or user ID."
  param_group :user
  param_group :pagination_with_ids
  def timeline
    @user = require_user
    @tweets = paginate(@user.tweets.reacted.order_by_id)
  end

  get "tweets/discoveries"
  description "Returns the Tweets which a user specified by username or user ID discovered."
  param_group :user
  param_group :pagination_with_ids
  def discoveries
    @user = require_user
    @tweets = paginate(Tweet.discovered_by(@user).order_by_id)
  end

  get "tweets/favorites"
  description "Returns the Tweets which a user specified by username or user ID favorited."
  param_group :user
  param_group :pagination_with_ids
  def favorites
    @user = require_user
    @tweets = paginate(Tweet.favorited_by(@user).order_by_id)
  end

  get "tweets/retweets"
  description "Returns the Tweets which a user specified by username or user ID retweeted."
  param_group :user
  param_group :pagination_with_ids
  def retweets
    @user = require_user
    @tweets = paginate(Tweet.retweeted_by(@user).order_by_id)
  end

  get "tweets/discovered_by"
  description "Returns the Tweets which a user specified by username or user ID retweeted."
  param_group :user
  optional :source_user_id, :integer, "The numerical ID of the subject user."
  optional :source_screen_name, :string, "The username of the subject user."
  param_group :pagination_with_ids
  def discovered_by
    @user = require_user
    @source_user = require_user(user_id: params[:source_user_id], screen_name: params[:source_screen_name])
    @tweets = paginate(@user.tweets.discovered_by(@source_user).order_by_id)
  end

  get "tweets/all_best"
  param_group :pagination_with_page_number
  def all_best
    @tweets = paginate_with_page_number(Tweet.reacted.order_by_reactions)
  end

  get "tweets/all_recent"
  param_group :pagination_with_page_number
  def all_recent
    @tweets = paginate_with_page_number(Tweet.recent.reacted.order_by_reactions)
  end

  get "tweets/all_timeline"
  param_group :pagination_with_ids
  def all_timeline
    @tweets = paginate(Tweet.reacted.order_by_id)
  end

  get "tweets/search"
  param_group :pagination_with_ids
  def search
    @tweets = paginate(Tweet.recent(7).parse_query(params[:q].to_s || "").reacted.not_protected.order_by_id)
  end

  private
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
    page = [params[:page].to_i, 1].max
    @prev_url = page == 1 ? nil : url_for(params.merge(page: page - 1))
    @next_url = url_for(params.merge(page: page + 1))
    tweets.limit(params_count).page(page)
  end

  def params_count
    @_count ||= [Settings.tweets.count.max, (params[:count] || Settings.tweets.count.default).to_i].min
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

