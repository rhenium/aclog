class ApplicationController < ActionController::Base
  protect_from_forgery
  after_filter :set_content_type

  def set_content_type
    if request.format == :html
      response.content_type = "application/xhtml+xml"
    end
  end

  def get_page_number(params)
    if params[:page] && i = params[:page].to_i
      if i > 0
        return i
      end
    end
    return 1
  end

  def prepare_cache
    # check
    return unless @items

    @favorite_cache = Favorite.where(@items.map{|m| "tweet_id = #{m.id}"}.join(" OR ")).sort_by{|m| m.id}.group_by{|m| m.tweet_id}
    @retweet_cache = Retweet.where(@items.map{|m| "tweet_id = #{m.id}"}.join(" OR ")).sort_by{|m| m.id}.group_by{|m| m.tweet_id}
    @user_cache = Hash[User.where(
        (@items.to_a + @favorite_cache.values + @retweet_cache.values).flatten.map{|m| m.user_id}.uniq
        .map{|m| "id = #{m}"}.join(" OR "))
      .map{|m| [m.id, m]}]
  end
end
