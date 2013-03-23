class IController < ApplicationController
  def best
    @items = Tweet
      .reacted
      .order_by_reactions
      .limit(Settings.page_per)
  end

  def recent
    @items = Tweet
      .recent
      .reacted
      .order_by_reactions
      .limit(Settings.page_per)
  end
end
