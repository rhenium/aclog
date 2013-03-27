class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :get_include_user
  after_filter :set_content_type

  def set_content_type
    if request.format == :html
      response.content_type = "application/xhtml+xml"
    end
  end

  def get_include_user
    case params[:include_user]
    when /^t/
      @include_user = true
    end
    @include_user ||= false
  end

  def render_tweets(a = nil, &blk)
    @items = (a || blk.call).page(page).per(count)

    render "shared/tweets"
  end

  def page
    if params[:page]
      i = params[:page].to_i
      if i > 0
        ret = i
      end
    end
    ret || 1
  end

  def count
    if params[:count]
      i = params[:count].to_i
      if (1..100) === i
        ret = i
      end
    end
    ret || Settings.page_per
  end
end
