class IController < ApplicationController
  def show
    id = params[:id].to_i
    @item = Tweet.find_by(:id => id)
    @user_cache = get_user_cache([@item])
    @title = "\"#{ApplicationController.helpers.strip_tags(ApplicationController.helpers.format_tweet_text(@item.text))[0...30]}\" from @#{@user_cache[@item.user_id].screen_name}"
  end
end
