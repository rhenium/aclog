class IController < ApplicationController
  def show
    id = params[:id].to_i
    items = Tweet.where(:id => id)
    if items.count > 0
      @items = items.page(1)
      @title = "\"#{ApplicationController.helpers.strip_tags(ApplicationController.helpers.format_tweet_text(items.first.text))[0...30]}\" from @#{items.first.user.screen_name}"
    else
      @items = []
    end
  end
end
