class Internal::TweetsController < Internal::ApplicationController
  before_action :load_user, only: [:user_best, :user_timeline, :user_favorites, :user_favorited_by]

  def responses
    @tweet = authorize! Tweet.find(params[:id])
  end

  def update
    @tweet = authorize! Tweet.update_from_twitter(params[:id], current_user).first
    @user = authorize! @tweet.user
    render :show
  end

  # action specific:
  def show
    @tweet = Tweet.find(params[:id])
    @user = authorize! @tweet.user
  end

  def user_best
    @tweets = @user.tweets.reacted.parse_recent(params[:recent]).order_by_reactions.paginate(params)
  end

  def user_timeline
    @tweets = @user.tweets.reacted(params[:reactions]).order_by_id.paginate(params)
  end

  def user_favorites
    @tweets = Tweet.reacted(params[:reactions]).favorited_by(@user).order("favorites.id DESC").includes(user: :account).paginate(params)
  end

  def user_favorited_by
    @source_user = authorize! User.find(screen_name: params[:source_screen_name])
    @tweets = @user.tweets.reacted(params[:reactions]).favorited_by(@source_user).order_by_id.paginate(params)
  end

  def all_best
    @tweets = Tweet.reacted.parse_recent(params[:recent]).order_by_reactions.includes(user: :account).paginate(params)
  end

  def all_timeline
    @tweets = Tweet.reacted(params[:reactions]).order_by_id.includes(user: :account).paginate(params)
  end

  def filter
    @tweets = Tweet.recent((params[:period] || 7).days).filter_by_query(params[:q].to_s).order_by_id.includes(user: :account).paginate(params)
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

  def load_user
    @user = authorize! User.find(screen_name: params[:screen_name])
  end
end
