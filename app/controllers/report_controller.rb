# -*- coding: utf-8 -*-
class ReportController < ApplicationController
  layout "index"
  def index
    # いんでっくす
  end

  private
  def get_tweet_id(str)
    case str
    when /^(?:(?:https?:\/\/)?(?:(?:www\.)?twitter\.com|aclog\.koba789\.com)\/(?:i\/|[0-9A-Za-z_]{1,15}\/status(?:es)?\/))?(\d+)/
      $1.to_i
    end
  end
end
