# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_format
  after_filter :xhtml
  helper_method :logged_in?, :page
  helper_method :get_bool, :get_int

  def render_timeline(a = nil, &blk)
    @items = a || blk.call

    @items = @items.where("tweets.id <= ?", max_id) if max_id
    @items = @items.where("tweets.id > ?", since_id) if since_id

    @items = @items.limit(count)
    @items = @items.offset(((page || 1) - 1) * count) if page

    render "shared/tweets"
  end

  def logged_in?; session[:user_id] != nil end

  # params
  def page; get_int(params[:page], nil){|i| i > 0} end
  def count; get_int(params[:count], 10){|i| (1..100) === i} end
  def max_id; get_int(params[:max_id], nil){|i| i >= 0} end
  def since_id; get_int(params[:since_id], nil){|i| i >= 0} end

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

  def get_bool(str)
    /^(t|true|1)$/ =~ str
  end

  def get_int(str, default = 0, &blk)
    if str =~ /^[1-9]\d*$/
      i = str.to_i
      if !block_given? || blk.call(i)
        return i
      end
    end
    default
  end
end
