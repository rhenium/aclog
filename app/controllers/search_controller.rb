# -*- coding: utf-8 -*-
require "shellwords"

class SearchController < ApplicationController
  before_filter :force_page

  def search
    @show_search = true

    # TODO: OR とか () とか対応したいよね
    unless params[:query]
      render_timeline(Tweet.where(id: -1))
      return
    end
    words = Shellwords.shellwords(params[:query])
    dateformat = "(20[0-9]{2})([-_\/]?)([0-9]{2})\\2([0-9]{2})" # $1: year, $3: month, $4: day

    result = words.inject(Tweet.order_by_id) do |tweets, word|
      case word
      when /^-?[a-z]+:.+$/
        # 特殊
        key, value = word.split(":", 2)
        case key.downcase
        when /^-?user$/
          user = User.cached(value)
          if key[0] == "-"
            tweets.where("user_id != ?", user ? user.id : -1)
          else
            tweets.where(user_id: user ? user.id : -1)
          end
        when /^-?fav/
          search_unless_zero(tweets, "favorites_count", key[0], value)
        when /^-?re?t/
          search_unless_zero(tweets, "retweets_count", key[0], value)
        when /^-?reactions?$/
          search_unless_zero(tweets, "favorites_count + retweets_count", key[0], value)
        when "order"
          case value
          when "old", /^asc/
            tweets.order("id ASC")
          when "reaction"
            tweets.order_by_reactions
          when /^fav/
            tweets.order_by_favorites
          when /^re?t/
            tweets.order_by_retweets
          else
            tweets
          end
        when /^-?text$/
          sourcetext = word.split(":", 2).last.gsub("%", "\\%").gsub("*", "%")
          sourcetext = "%#{sourcetext}%".gsub(/%+/, "%")
          op = key[0] == "-" ? " NOT LIKE " : " LIKE "
          tweets.where("text #{op} ?", sourcetext)
        when /^-?source$/
          sourcetext = word.split(":", 2).last.gsub("%", "\\%").gsub("*", "%")
          op = key[0] == "-" ? " NOT LIKE " : " LIKE "
          tweets.where("source #{op} ? OR source #{op} ?", "<url:%:#{sourcetext.gsub(":", "%3A")}>", "<url:%:#{CGI.escape(sourcetext)}>")
        else
          # unknown command
          tweets
        end
      when /^-?#{dateformat}\.\.#{dateformat}$/

        since = Time.utc($1.to_i, $3.to_i, $4.to_i) - 9 * 60 * 60
        to = Time.utc($5.to_i, $7.to_i, $8.to_i + 1) - 9 * 60 * 60

        if word[0] == "-"
          tweets.where("id < ? OR id >= ?", first_id_of_time(since), first_id_of_time(to))
        else
          tweets.where(id: first_id_of_time(since)...first_id_of_time(to))
        end
      else
        # TODO: ツイート検索
        tweets
      end
    end

    render_timeline(result)
  end

  private
  def first_id_of_time(time)
    p (time.to_i * 1000 - 1288834974657) << 22
  end

  def search_unless_zero(tweets, column, flag, value)
    num = Integer(value) rescue 0
    n = flag == "-"

    unless num == 0
      tweets.where("#{column} #{n ? "<" : ">="} ?", num)
    else
      tweets
    end
  end
end
