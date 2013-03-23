class UsersController < ApplicationController
  def show
    tweet_id = Integer(params[:id])

    @item = Tweet.find(tweet_id)
    @user = @item.user
    helpers = ApplicationController.helpers
    @title = "\"#{helpers.strip_tags(helpers.format_tweet_text(@item.text))[0...30]}\" from @#{@item.user.screen_name}"

    respond_to do |format|
      format.html do
        prepare_info
      end

      format.json do
        @trim_user = params[:trim_user] == "true"
      end
    end
  end

  def best
    user = render_timeline(params) do |tweets, user|
      tweets.of(user).reacted.order_by_reactions
    end
    @title = "@#{user.screen_name}'s Best Tweets"
  end

   def recent
    user = render_timeline(params) do |tweets, user|
      tweets.of(user).recent.reacted.order_by_reactions
    end
    @title = "@#{user.screen_name}'s Recent Best Tweets"
  end

  def timeline
    user = render_timeline(params) do |tweets, user|
      if params[:tweets] == "all"
        tweets.of(user).order_by_id
      else
        tweets.of(user).reacted.order_by_id
      end
    end
    @title = "@#{user.screen_name}'s Newest Tweets"

    if user.protected
      raise Exception # FIXME
    end
  end

  def my
    user = render_timeline(params) do |tweets, user|
      tweets.discovered(user).order_by_id
    end
    @title = "@#{user.screen_name}'s Recent Discoveries"
  end

  private
  def render_timeline(params, &g)
    page = get_page_number(params)
    screen_name = params[:screen_name]

    @user = User.where(:screen_name => screen_name).first
    unless @user
      raise ActiveRecord::RecordNotFound.new(screen_name)
    end

    @items = g.call(Tweet, @user)
      .page(page)
      .per(Settings.page_per)

    respond_to do |format|
      format.html do
        prepare_info
      end

      format.json do
        @trim_user = params[:trim_user] == "true"
      end
    end

    return @user
  end
end
