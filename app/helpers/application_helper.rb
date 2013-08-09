# -*- encoding: utf-8 -*-
module ApplicationHelper
  def format_time(dt)
    dt.to_time.localtime("+09:00").strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_tweet_text(text)
    ret = text.gsub(/<([a-z]+?)(?<!\\):(.+?)(?:(?<!\\):(.+?))?>/) do
      case $1
      when "mention"
        screen_name = CGI.unescape($2)
        link_to("@#{screen_name}", "/#{screen_name}")
      when "url"
        n = [$3, $2.gsub(/(https?)%3A/, "\\1:")].map {|m| m.gsub("\\:", ":") }
        link_to(*n)
      when "hashtag"
        hashtag = CGI.unescape($2)
        link_to("##{hashtag}", "https://twitter.com/search?q=#{CGI.escape("##{hashtag}")}")
      when "symbol"
        symbol = CGI.unescape($2)
        link_to("$#{symbol}", "https://twitter.com/search?q=#{CGI.escape("$#{symbol}")}")
      else
        $&
      end
    end
    return ret
  end
  alias format_source_text format_tweet_text

  def twitter_status_url(tweet)
    "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
  end

  def twitter_user_url(screen_name)
    "https://twitter.com/#{screen_name}"
  end

  def sidebar_type
    if @sidebar
      return @sidebar
    elsif @user
      return "users"
    else
      params[:controller]
    end
  end

  def caption
    "#{@caption}"
  end

  def title
    if @tweet
      text = CGI.unescapeHTML(strip_tags(format_tweet_text(@tweet.text)))
      @title = "\"#{text}\" from #{@user.screen_name}"
    end

    "#{@title || @caption} - aclog"
  end

  # utf8, form
  def utf8_enforcer_tag; raw "" end
end
