class Internal::TweetsController < Internal::ApplicationController
  def responses
    authorize! @tweet = Tweet.find(params[:id])
  end

  def update
    @tweet = Tweet.update_from_twitter(params[:id], current_user).first
    raise Aclog::Exceptions::TweetNotFound, params[:id] unless @tweet
    authorize! @user = @tweet.user
    render :show
  end

  def update_later
    TweetUpdateJob.perform_later(params[:id].to_i)
  end

  # action specific:
  def show
    @tweet = Tweet.find(params[:id])
    authorize! @user = @tweet.user
  end

  def user_best
    authorize! @user ||= User.find(screen_name: params[:screen_name])
    @tweets = @user.tweets.reacted.parse_recent(params[:recent]).order_by_reactions.paginate(params)
  end

  def user_timeline
    authorize! @user ||= User.find(screen_name: params[:screen_name])
    @tweets = @user.tweets.reacted(params[:reactions]).order_by_id.paginate(params)
  end

  def user_favorites
    authorize! @user = User.find(screen_name: params[:screen_name])
    @tweets = Tweet.reacted(params[:reactions]).favorited_by(@user).order("`favorites`.`id` DESC").eager_load(:user).paginate(params)
  end

  def user_favorited_by
    authorize! @user = User.find(screen_name: params[:screen_name])
    authorize! @source_user = User.find(screen_name: params[:source_screen_name])
    @tweets = @user.tweets.reacted(params[:reactions]).favorited_by(@source_user).order_by_id.eager_load(:user).paginate(params)
  end

  def all_best
    @tweets = Tweet.reacted.parse_recent(params[:recent]).order_by_reactions.eager_load(:user).paginate(params)
  end

  def all_timeline
    @tweets = Tweet.reacted(params[:reactions]).order_by_id.eager_load(:user).paginate(params)
  end

  def filter
    @tweets = Tweet.recent((params[:period] || 7).days).filter_by_query(params[:q].to_s).order_by_id.eager_load(:user).paginate(params)
  end

  private
  def render(*args)
    return super(*args) if args.size > 0

    if template_exists?(params[:action], _prefixes)
      super
    else
      if @tweets
        super("tweets")
      else
        # bug
      end
    end
  end
end
