class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_content_type

  def set_content_type
    request.format = :xhtml if request.format == :html
  end

  def get_page_number(params)
    if params[:page]
      i = params[:page].to_i
      if i && i > 0
        return i
      else
        return 1
      end
    end
  end
end
