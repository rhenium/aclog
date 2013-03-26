class ApplicationController < ActionController::Base
  protect_from_forgery
  after_filter :set_content_type

  def set_content_type
    if request.format == :html
      response.content_type = "application/xhtml+xml"
    end
  end
end
