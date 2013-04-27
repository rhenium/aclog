class IController < ApplicationController
  def best
    @title = "Best Tweets"
    render_tweets(force_page: true) do
      Tweet
        .reacted
        .original
        .order_by_reactions
    end
  end

  def recent
    @title = "Recent Best Tweets"
    render_tweets(force_page: true) do
      Tweet
        .recent
        .reacted
        .original
        .order_by_reactions
    end
  end

  def timeline
    @title = "Public Timeline"
    render_tweets do
      Tweet
        .reacted
        .not_protected
        .order_by_id
    end
  end
end
