class SearchController < ApplicationController
  include Aclog::Twitter

  def search
    @caption = "search"
    @tweets = Tweet.parse_query(params[:query].to_s || "").reacted.order_by_id.list(params, force_page: true)
    @tweets = @tweets.recent(7) unless @tweets.to_sql.include?("`tweets`.`id`")
  end
end
