class TweetsController < ApplicationController
  before_action :load_user, only: [:user_best, :user_timeline, :user_favorites, :user_favorited_by]

  def responses
    tweet = authorize! Tweet.find(params[:id])
    render_json data: extract_reactions(tweet)
  end

  def show
    @tweet = begin
      t = Tweet.find(params[:id])
      TweetUpdateJob.perform_later(t.id) unless bot_request?
      t
    rescue ActiveRecord::RecordNotFound
      Tweet.update_from_twitter(params[:id], current_user)
      Tweet.find(params[:id])
    end
    @user = authorize! @tweet.user
    render_show
  end

  def update
    Tweet.update_from_twitter(params[:id], current_user)
    @tweet = authorize! Tweet.find(params[:id])
    @user = @tweet.user
    render_show
  end

  def user_best
    @tweets = @user.tweets.reacted.parse_recent(params[:recent]).order_by_reactions.paginate(params)
    render_tweets
  end

  def user_timeline
    @tweets = @user.tweets.reacted(params[:reactions]).order_by_id.paginate(params)
    render_tweets
  end

  def user_favorites
    @tweets = Tweet.reacted(params[:reactions]).favorited_by(@user).order("favorites.id DESC").includes(user: :account).paginate(params)
    render_tweets
  end

  def user_favorited_by
    @source_user = authorize! User.find(screen_name: params[:source_screen_name])
    @tweets = @user.tweets.reacted(params[:reactions]).favorited_by(@source_user).order("favorites.tweet_id DESC").paginate(params)
    render_tweets
  end

  def all_best
    @tweets = Tweet.reacted.parse_recent(params[:recent]).order_by_reactions.includes(user: :account).paginate(params)
    render_tweets
  end

  def all_timeline
    @tweets = Tweet.reacted(params[:reactions]).order_by_id.includes(user: :account).paginate(params)
    render_tweets
  end

  def filter
    @tweets = Tweet.recent((params[:period] || 7).days).filter_by_query(params[:q].to_s).order_by_id.includes(user: :account).paginate(params)
    render_tweets
  end

  private
  def render_show
    sts = []

    @tweet.reply_ancestors(2).each { |t|
      sts << transform_tweet(t).merge(aside: true) }
    sts << transform_tweet(@tweet)
    @tweet.reply_descendants(2).each { |t|
      sts << transform_tweet(t).merge(aside: true) }

    render_json data: {
      user: @user.as_json(methods: :registered),
      statuses: sts }
  end

  def render_tweets
    if request.format.atom?
      return render("tweets")
    end

    hash = {
      user: @user.as_json(methods: :registered),
      statuses: @tweets.map(&method(:transform_tweet)) }

    if @tweets.length > 0
      if !params[:page] && @tweets.order_values.all? {|o| !o.is_a?(String) && o.expr.name == :id }
        hash[:prev] = params.dup.tap {|h| h.delete(:max_id) }.merge!(since_id: @tweets.first.id.to_s)
        hash[:next] = params.dup.tap {|h| h.delete(:since_id) }.merge!(max_id: (@tweets.last.id - 1).to_s)
      else
        page = [params[:page].to_i, 1].max
        hash[:prev] = page == 1 ? nil : params.merge(page: page - 1)
        hash[:next] = params.merge(page: page + 1)
      end
    end

    render_json data: hash
  end

  def transform_tweet(tweet)
    if !authorized?(tweet.user)
      { allowed: false,
        tweeted_at: tweet.tweeted_at }
    elsif tweet.user.opted_out?
      { allowed: false,
        id_str: tweet.id.to_s,
        tweeted_at: tweet.tweeted_at }
    else
      hash = {
        allowed: true,
      }.merge!(tweet.serializable_hash(include: :user))

      if tweet.reactions_count <= 20
        hash.merge!(extract_reactions(tweet))
        hash[:include_reactions] = true
      end

      hash
    end
  end

  def extract_reactions(tweet)
    tr = -> u {
      (current_user == tweet.user || authorized?(u)) ? u : nil
    }

    { favorites: tweet.favoriters.map(&tr),
      retweets: tweet.retweeters.map(&tr) }
  end

  def load_user
    @user = authorize! User.find(screen_name: params[:screen_name])
  end
end
