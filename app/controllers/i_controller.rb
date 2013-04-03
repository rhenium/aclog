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

  def report
    if request.post?
      case params[:type]
      when "steal"
        # パクリツイート

      end
    end
  end
end
