class IController < ApplicationController
  before_filter :force_page, only: [:best, :recent]

  def best
    @title = "Best Tweets"
    render_timeline do
      Tweet
        .reacted
        .original
        .order_by_reactions
    end
  end

  def recent
    @title = "Recent Best Tweets"
    render_timeline do
      Tweet
        .recent
        .reacted
        .original
        .order_by_reactions
    end
  end

  def timeline
    @title = "Public Timeline"
    render_timeline do
      Tweet
        .reacted
        .not_protected
        .order_by_id
    end
  end

  private
  def force_page
    params[:page] = "1" unless page
  end
end
