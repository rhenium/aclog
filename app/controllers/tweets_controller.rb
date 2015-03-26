class TweetsController < ApplicationController
  def show
    @tweet = Tweet.find(params[:id])
    @user = @tweet.user
    authorize_to_show_user! @user
  rescue ActiveRecord::RecordNotFound
    import
  end

  def responses
    show
  end

  def import
    tweet = Tweet.find_by(id: params[:id])

    if tweet && tweet.user.registered?
      account = tweet.user.account
    elsif logged_in?
      account = current_user.account
    else
      account = nil
    end

    tweet = Tweet.import_from_twitter(params[:id], account)
    redirect_to tweet
  end

  def user_index
    @user = require_user
    authorize_to_show_user! @user

    if @user.registered?
      user_best
      render :user_best
    else
      user_timeline
      render :user_timeline
    end
  end

  def user_best
    @user = require_user
    authorize_to_show_user! @user

    @tweets = paginate_with_page_number @user.tweets.reacted.parse_recent(params[:recent]).order_by_reactions
  end

  def user_timeline
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate @user.tweets.reacted(params[:reactions]).order_by_id
  end

  def user_favorites
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate_with_page_number Tweet.reacted(params[:reactions]).favorited_by(@user).order("`favorites`.`id` DESC").eager_load(:user)
  end

  def user_favorited_by
    @user = require_user
    authorize_to_show_user! @user
    @source_user = User.find(id: params[:source_user_id], screen_name: params[:source_screen_name])
    authorize_to_show_user! @source_user
    @tweets = paginate @user.tweets.reacted(params[:reactions]).favorited_by(@source_user).order_by_id.eager_load(:user)
  end

  def all_best
    @tweets = paginate_with_page_number Tweet.reacted.parse_recent(params[:recent]).order_by_reactions.eager_load(:user)
  end

  def all_timeline
    @tweets = paginate Tweet.reacted(params[:reactions]).order_by_id.eager_load(:user)
  end

  def filter
    @tweets = paginate Tweet.recent((params[:period] || 7).days).filter_by_query(params[:q].to_s).order_by_id.eager_load(:user)
  end

  private
  def require_user
    User.find(id: params[:user_id], screen_name: params[:screen_name])
  end

  def paginate(tweets)
    if params[:page]
      paginate_with_page_number tweets
    else
      tweets.limit(params_count).max_id(params[:max_id]).since_id(params[:since_id])
    end
  end

  def paginate_with_page_number(tweets)
    @page = (params[:page] || 1).to_i
    tweets.page(@page, params_count)
  end

  def params_count
    [(params[:count] || Settings.tweets.count.default).to_i, Settings.tweets.count.max].min
  end

  def render(*args)
    if @tweets && @tweets.length > 0
      if @page
        @prev_url = @page == 1 ? nil : url_for(params.merge(page: @page - 1))
        @next_url = url_for(params.merge(page: @page + 1))
      else
        @prev_url = url_for(params.tap {|h| h.delete(:max_id) }.merge(since_id: @tweets.first.id))
        @next_url = url_for(params.tap {|h| h.delete(:since_id) }.merge(max_id: @tweets.last.id - 1))
      end
    end

    if request.format == :json
      if !template_exists?(params[:action], params[:controller], true)
        if @tweets
          return super("tweets")
        end
      end
    end

    super
  end
end
