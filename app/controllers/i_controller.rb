class IController < ApplicationController
  def best
    @items = Tweet
      .reacted
      .order_by_reactions
      .limit(get_page_count(params))
  end

  def recent
    @items = Tweet
      .recent
      .reacted
      .order_by_reactions
      .limit(get_page_count(params))
  end

  def show
    tweet_id = Integer(params[:id])

    @item = Tweet.find(tweet_id)
    @user = @item.user
    helpers = ApplicationController.helpers
    @title = "\"#{helpers.strip_tags(helpers.format_tweet_text(@item.text))[0...30]}\" from @#{@item.user.screen_name}"

    respond_to do |format|
      format.html

      format.json do
       @include_user = params[:include_user] == "true"
      end
    end
  end
end
