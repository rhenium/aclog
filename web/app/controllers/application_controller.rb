class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_content_type

  def set_content_type
    request.format = :xhtml if request.format == :html
  end

  def get_page_number(params)
    if params[:page] && i = params[:page].to_i
      if i > 0
        return i
      end
    end
    return 1
  end

  def get_user_cache(items)
    Hash[
      User.find(@items
        .map{|m| m.favorites.map{|u| u.user_id} + m.retweets.map{|u| u.user_id}}
        .flatten
        .uniq)
      .map{|m| [m.id, m]}
    ]
  end
end
