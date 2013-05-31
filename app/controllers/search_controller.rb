class SearchController < ApplicationController
  include Aclog::Twitter

  def search
    @caption = "search"
    @tweets = Tweet.recent(7).parse_query(params[:query] || "").reacted.order_by_id.list(params, force_page: true)
  end
end
