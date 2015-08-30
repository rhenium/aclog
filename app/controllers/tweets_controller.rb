class TweetsController < ApplicationController
  def show
    @tweet ||= begin
      t = Tweet.find(params[:id])
      TweetUpdateJob.perform_later(t.id) unless bot_request?
      t
    rescue ActiveRecord::RecordNotFound
      Tweet.update_from_twitter(params[:id], current_user).first || (raise Aclog::Exceptions::TweetNotFound, params[:id])
    end

    authorize! @user = @tweet.user

    @sidebars = [:user]
    @title = "\"#{CGI.unescapeHTML(@tweet.text).truncate(30)}\" from #{@user.name} (@#{@user.screen_name})"
    @header = "@#{@user.screen_name}'s Tweet"
  end

  def user_index
    authorize! @user = User.find(screen_name: params[:screen_name])

    if @user.registered?
      params[:action] = "user_best"
      user_best
    else
      params[:action] = "user_timeline"
      user_timeline
    end
  end

  def user_best
    authorize! @user ||= User.find(screen_name: params[:screen_name])

    @sidebars = [:user, :recent_thresholds]
    @title = "@#{@user.screen_name}'s Best Tweets"
  end

  def user_timeline
    authorize! @user ||= User.find(screen_name: params[:screen_name])

    @sidebars = [:user, :reactions_thresholds]
    @title = "@#{@user.screen_name}'s Timeline"

    if request.format == :atom
      @tweets = @user.tweets.reacted(params[:reactions]).order_by_id.paginate(params)
    end
  end

  def user_favorites
    authorize! @user = User.find(screen_name: params[:screen_name])

    @sidebars = [:user, :reactions_thresholds]
    @title = "@#{@user.screen_name}'s Favorites"
  end

  def user_favorited_by
    authorize! @user = User.find(screen_name: params[:screen_name])
    authorize! @source_user = User.find(screen_name: params[:source_screen_name])

    @sidebars = [:user, :reactions_thresholds]
    @title = "@#{@user.screen_name}'s Tweets favorited by @#{@source_user.screen_name}"
  end

  def all_best
    @sidebars = [:all, :recent_thresholds]
    @title = "Top Tweets"
  end

  def all_timeline
    @sidebars = [:all, :reactions_thresholds]
    @title = "Public Timeline"
  end

  def filter
    @sidebars = [:all]
    @title = "Filter"
  end

  private
  def render(*args)
    return super(*args) if args.size > 0

    if template_exists?(params[:action], _prefixes)
      super
    else
      super("tweets")
    end
  end
end
