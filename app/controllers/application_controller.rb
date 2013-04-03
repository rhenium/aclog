# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_format, :get_include_user, :get_include_user_stats
  after_filter :xhtml

  def set_format
    unless request.format == :json || request.format == :html
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

  def get_include_user_stats
    if @include_user_stats ||= get_bool(params[:include_user_stats])
      @include_user = true
    end
  end

  def render_tweets(a = nil, &blk)
    @items = a || blk.call

    if max_id
      @items = @items.where("id <= ?", max_id)
    end

    if since_id
      @items = @items.where("id > ?", since_id)
    end

    @items = @items.page(page || 1).per(count)

    render "shared/tweets"
  end

  def page; get_int(params[:page], nil){|i| i > 0} end

  def count; get_int(params[:count], 10){|i| (1..100) === i} end

  def max_id; get_int(params[:max_id], nil) end

  def since_id; get_int(params[:since_id], nil) end

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

  def all
    get_bool(params[:all])
  end

  private
  def get_bool(str)
    if /^(t.*|1)$/ =~ str
      true
    else
      false
    end
  end

  def get_int(str, default = 0, &blk)
    if str =~ /^\d+$/
      i = str.to_i
      if !block_given? || blk.call(i)
        return i
      end
    end
    default
  end
end
