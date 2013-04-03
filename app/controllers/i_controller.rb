class IController < ApplicationController
  def best
    @title = "Best Tweets"
    render_page do
      Tweet
        .reacted
        .order_by_reactions
        .original
    end
  end

  def recent
    @title = "Recent Best Tweets"
    render_page do
      Tweet
        .recent
        .reacted
        .order_by_reactions
        .original
    end
  end

  def timeline
    @title = "Public Timeline"
    render_timeline do
      Tweet
        .reacted
        .order_by_id
    end
  end
end
