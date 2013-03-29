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
    @items = (a || blk.call).page(page).per(count)

    render "shared/tweets"
  end

  def page
    get_int(params[:page], 1) do |i|
      i > 0
    end
  end

  def count
    get_int(params[:count], 10) do |i|
      (1..100) === i
    end
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

  def get_int(str, default, &blk)
    i = Integer(str) rescue default
    if blk.call(i)
      i
    else
      default
    end
  end
end
