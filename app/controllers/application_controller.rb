# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_format
  after_filter :xhtml
  before_filter :get_include_user

  def render_timeline(a = nil, &blk)
    @items = a || blk.call

    @items = @items.where("tweets.id <= ?", max_id) if max_id
    @items = @items.where("tweets.id > ?", since_id) if since_id

    if @force_page || page
      @items = @items.page(page || 1).per(count)
    else
      @items = @items.limit(count)
    end

    render "shared/tweets"
  end

  # params
  def page; get_int(params[:page], nil){|i| i > 0} end
  def count; get_int(params[:count], 10){|i| (1..100) === i} end
  def max_id; get_int(params[:max_id], nil){|i| i >= 0} end
  def since_id; get_int(params[:since_id], nil){|i| i >= 0} end
  def user_limit; get_int(params[:limit], 20){|i| i >= 0} end

  def force_page
    @force_page = true
  end

  def order
    case params[:order]
    when /^fav/
      :favorite
    when /^re?t/
      :retweet
    else
      :default
    end
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

  def get_include_user
    @include_user ||= get_bool(params[:include_user])
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
