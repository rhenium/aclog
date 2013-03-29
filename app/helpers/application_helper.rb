require "time"

module ApplicationHelper
  def format_time(dt)
    dt.to_time.localtime("+09:00").strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_date_ago(dt)
    "#{(DateTime.now.utc - dt.to_datetime).to_i}d ago"
  end

  def format_tweet_text(text)
    text
      .gsub(/<url:(.+?):(.+?)>/){link_to(CGI.unescape($2), CGI.unescape($1), :target => "_blank")}
      .gsub(/<hashtag:(.+?)>/){link_to("##{CGI.unescape($1)}", "https://twitter.com/search?q=%23#{$1}")}
      .gsub(/<cashtag:(.+?)>/){link_to("$#{CGI.unescape($1)}", "https://twitter.com/search?q=%23#{$1}")}
      .gsub(/<mention:(.+?)>/){link_to("@#{CGI.unescape($1)}", "/#{$1}")}
      .gsub(/\r\n|\r|\n/, "<br />")
  end

  def format_source_text(text)
    format_tweet_text(text)
  end

  def twitter_status_url(tweet)
    "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
  end

  def twitter_user_url(screen_name)
    "https://twitter.com/#{screen_name}"
  end

  def link_to_user_page(screen_name, &blk)
    if block_given?
      body = capture(&blk)
    end

    body ||= "@#{screen_name}"
    link_to(body, :controller => "users", :action => "best", :screen_name => screen_name)
  end

  # utf8
  def utf8_enforcer_tag
    ""
  end
end
