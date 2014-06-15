class TweetsController < ApplicationController
  after_action :eager_load_user

  def show
    @tweet = Tweet.find(params[:id])
    @user = @tweet.user
    authorize_to_show_user! @user
  rescue
    import
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

    tweet = Tweet.import_from_twitter(params[:id], account.client)
    redirect_to tweet
  end

  def user_index
    @user = require_user
    authorize_to_show_user! @user

    if authorized_to_show_user_best? @user
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
    authorize_to_show_user_best! @user
    @tweets = paginate_with_page_number @user.tweets.reacted.order_by_reactions
  end

  def user_recent
    @user = require_user
    authorize_to_show_user! @user
    authorize_to_show_user_best! @user
    @tweets = paginate_with_page_number @user.tweets.reacted.recent.order_by_reactions
  end

  def user_timeline
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate @user.tweets.reacted(params[:reactions]).order_by_id
  end

  def user_favorites
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate_with_page_number Tweet.reacted(params[:reactions]).favorited_by(@user).order("`favorites`.`id` DESC")
  end

  def user_favorited_by
    @user = require_user
    authorize_to_show_user! @user
    @source_user = User.find(id: params[:source_user_id], screen_name: params[:source_screen_name])
    authorize_to_show_user! @source_user
    @tweets = paginate @user.tweets.reacted(params[:reactions]).favorited_by(@source_user).order_by_id
  end

  def all_best
    @tweets = paginate_with_page_number Tweet.reacted.order_by_reactions
  end

  def all_recent
    @tweets = paginate_with_page_number Tweet.recent.reacted.order_by_reactions
  end

  def all_timeline
    @tweets = paginate Tweet.reacted(params[:reactions]).order_by_id
  end

  def filter
    @tweets = paginate Tweet.recent(7.days).filter_by_query(params[:q].to_s).order_by_id.eager_load(:user)
    if params[:registered]
      @tweets = @tweets.to_a.select {|t| t.user.registered? }
    end
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

  def eager_load_user
    if @tweets && @tweets.is_a?(ActiveRecord::Relation)
      @tweets = @tweets.eager_load(:user)
    end
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

    if @tweets && request.xhr?
      super(json: { html: render_to_string(partial: "tweet", collection: @tweets, as: :tweet, formats: :html),
                    next_url: @next_url,
                    prev_url: @prev_url })
    else
      super(*args)
    end
  end
end
