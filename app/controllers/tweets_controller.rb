class TweetsController < ApplicationController
  def show
    @tweet ||= begin
      Tweet.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Tweet.update_from_twitter(params[:id], current_user)
    end

    authorize! @user = @tweet.user

    @sidebars = [:user]
    @title = "\"#{view_context.truncate(CGI.unescapeHTML(@tweet.text))}\" from #{@user.name} (@#{@user.screen_name})"
    @header = "@#{@user.screen_name}'s Tweet"
  end

  def update
    @tweet = Tweet.update_from_twitter(params[:id], current_user)
    show
    render :show
  end

  def i_responses
    authorize! @tweet = Tweet.find(params[:id])
  end

  def user_index
    authorize! @user = User.find(screen_name: params[:screen_name])

    if @user.registered?
      user_best
    else
      user_timeline
    end
  end

  def user_best
    authorize! @user ||= User.find(screen_name: params[:screen_name])
    @tweets = @user.tweets.reacted.parse_recent(params[:recent]).order_by_reactions.paginate(params)

    @sidebars = [:user, :recent_thresholds]
    @title = "@#{@user.screen_name}'s Best Tweets"
  end

  def user_timeline
    authorize! @user ||= User.find(screen_name: params[:screen_name])
    @tweets = @user.tweets.reacted(params[:reactions]).order_by_id.paginate(params)

    @sidebars = [:user, :reactions_thresholds]
    @title = "@#{@user.screen_name}'s Timeline"
  end

  def user_favorites
    authorize! @user = User.find(screen_name: params[:screen_name])
    @tweets = Tweet.reacted(params[:reactions]).favorited_by(@user).order("`favorites`.`id` DESC").eager_load(:user).paginate(params)

    @sidebars = [:user, :reactions_thresholds]
    @title = "@#{@user.screen_name}'s Favorites"
  end

  def user_favorited_by
    authorize! @user = User.find(screen_name: params[:screen_name])
    authorize! @source_user = User.find(screen_name: params[:source_screen_name])
    @tweets = @user.tweets.reacted(params[:reactions]).favorited_by(@source_user).order_by_id.eager_load(:user).paginate(params)

    @sidebars = [:user, :reactions_thresholds]
    @title = "@#{@user.screen_name}'s Tweets favorited by @#{@source_user.screen_name}"
  end

  def all_best
    @tweets = Tweet.reacted.parse_recent(params[:recent]).order_by_reactions.eager_load(:user).paginate(params)

    @sidebars = [:all, :recent_thresholds]
    @title = "Top Tweets"
  end

  def all_timeline
    @tweets = Tweet.reacted(params[:reactions]).order_by_id.eager_load(:user).paginate(params)

    @sidebars = [:all, :reactions_thresholds]
    @title = "Public Timeline"
  end

  def filter
    @tweets = Tweet.recent((params[:period] || 7).days).filter_by_query(params[:q].to_s).order_by_id.eager_load(:user).paginate(params)

    @sidebars = [:all]
    @title = "Filter"
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
