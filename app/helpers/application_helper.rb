require "time"

module ApplicationHelper
  def format_tweet_created_at(dt)
    dt.to_time.localtime("+09:00").strftime("%Y-%m-%d %H:%M:%S")
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

  def status_url(tweet)
    "/#{@user_cache[tweet.user_id].screen_name}/status/#{tweet.id}"
  end

  def twitter_status_url(tweet)
    "https://twitter.com/#{@user_cache[tweet.user_id].screen_name}/status/#{tweet.id}"
  end

  def user_url(user_id)
    "/#{@user_cache[user_id].screen_name}"
  end
end
