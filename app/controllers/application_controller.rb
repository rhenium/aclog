# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_format
  after_filter :xhtml

  def render_tweets(options = {}, &blk)
    if params[:count]
      count = params[:count].to_i
    else
      count = 10
    end
    p options
    if options[:force_page]
      params[:page] ||= "1"
    end
    
    @items = blk.call.limit(count)

    if params[:page]
      @items = @items.page(params[:page].to_i, count)
    else
      @items = @items.max_id(params[:max_id].to_i) if params[:max_id]
      @items = @items.since_id(params[:since_id].to_i) if params[:since_id]
    end
    
    render "shared/tweets"
  end

  private
  def set_format
    unless [:json, :html].include?(request.format.to_sym)
      request.format = :html
    end
  end

  def xhtml
    if request.format == :html
      response.content_type = "application/xhtml+xml"

      # remove invalid charactors
      response.body = response.body.gsub(/[\x0-\x8\xb\xc\xe-\x1f]/, "")
    end
  end
end
