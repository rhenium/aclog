class IController < ApplicationController
  def best
    @title = "Best Tweets"
    render_tweets do
      Tweet
        .reacted
        .order_by_reactions
    end
  end

  def recent
    @title = "Recent Best Tweets"
    render_tweets do
      Tweet
        .recent
        .reacted
        .order_by_reactions
    end
  end

  def timeline
    @title = "Public Timeline"
    render_tweets do
      Tweet
        .reacted
        .order_by_id
    end
  end

  def show
    tweet_id = params[:id].to_i
    if tweet_id == 0
      raise Exception.new # FIXME
    end
    items = Tweet.where(:id => tweet_id)
    @user = items.first.user

    helpers = ApplicationController.helpers
    @title = "\"#{helpers.strip_tags(helpers.format_tweet_text(items.text))[0...30]}\" from @#{@user.screen_name}"
    @title_b = "@#{@user.screen_name}'s Tweet"

    render_tweets(items)
  end
end
