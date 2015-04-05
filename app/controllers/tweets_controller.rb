class TweetsController < ApplicationController
  def show
    @tweet = Tweet.find(params[:id])
    authorize! @user = @tweet.user

    @sidebars = [:user]
    @title = "\"#{view_context.truncate(CGI.unescapeHTML(@tweet.text))}\" from #{@user.name} (@#{@user.screen_name})"
    @header = "@#{@user.screen_name}'s Tweet"
  rescue ActiveRecord::RecordNotFound
    import
  end

  def import
    tweet = Tweet.import_from_twitter(params[:id], current_user)
    redirect_to tweet
  end

  def responses
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

    #raise StandardError, request.formats
    if template_exists?(params[:action], params[:controller], true, [], formats: request.formats)
      super
    else
      if @tweets
        super("tweets")
      else
        super # bug
      end
    end
  end
end
