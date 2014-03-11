class TweetsController < ApplicationController
  def show
    @tweet = Tweet.find_by(id: params[:id])
    if @tweet
      @user = @tweet.user
      authorize_to_show_user! @user
    else
      import
    end
  end

  def import
    if logged_in?
      tweet = Tweet.import(params[:id], current_user.account.client)
    else
      tweet = Tweet.import(params[:id])
    end
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
    @tweets = paginate_with_page_number(@user.tweets.reacted.order_by_reactions).eager_load_for_html
  end

  def user_recent
    @user = require_user
    authorize_to_show_user! @user
    authorize_to_show_user_best! @user
    @tweets = paginate_with_page_number(@user.tweets.reacted.recent.order_by_reactions).eager_load_for_html
  end

  def user_timeline
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate(@user.tweets.reacted(params[:reactions]).order_by_id).eager_load_for_html
  end

  def user_discoveries
    @user = require_user
    authorize_to_show_user! @user
    @tweets = paginate_with_page_number(Tweet).reacted(params[:reactions]).discovered_by(@user).order_by_id.eager_load_for_html
  end

  def user_discovered_by
    @user = require_user
    authorize_to_show_user! @user
    @source_user = User.find(id: params[:source_user_id], screen_name: params[:source_screen_name])
    authorize_to_show_user! @source_user
    @tweets = paginate_with_page_number(@user.tweets).reacted(params[:reactions]).discovered_by(@source_user).order_by_id.eager_load_for_html
  end

  def all_best
    @tweets = paginate_with_page_number(Tweet.not_protected.registered.reacted.order_by_reactions).eager_load_for_html
  end

  def all_recent
    @tweets = paginate_with_page_number(Tweet.not_protected.registered.recent.reacted.order_by_reactions).eager_load_for_html
  end

  def all_timeline
    @tweets = paginate(Tweet.reacted(params[:reactions]).order_by_id).eager_load_for_html
  end

  def filter
    @tweets = paginate(Tweet.reacted.recent(7).filter_by_query(params[:q].to_s).order_by_id).eager_load_for_html
  end

  private
  def require_user
    User.find(id: params[:user_id], screen_name: params[:screen_name])
  end

  def paginate(tweets)
    if params[:page]
      paginate_with_page_number(tweets)
    else
      tweets.limit(params_count).max_id(params[:max_id]).since_id(params[:since_id])
    end
  end

  def paginate_with_page_number(tweets)
    @page = (params[:page] || 1).to_i
    tweets.limit(params_count).page(@page)
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

    if @tweets && request.xhr?
      super(json: { html: render_to_string(partial: "tweet", collection: @tweets, as: :tweet, formats: :html),
                    next_url: @next_url,
                    prev_url: @prev_url })
    else
      super(*args)
    end
  end
end

