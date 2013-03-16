class IController < ApplicationController
  def show
    id = params[:id].to_i
    @items = Tweet.where(:id => id).page(1)
    prepare_cache
    @title = "\"#{ApplicationController.helpers.strip_tags(ApplicationController.helpers.format_tweet_text(@items.first.text))[0...30]}\" from @#{@user_cache[@items.first.user_id].screen_name}"
  end
end
