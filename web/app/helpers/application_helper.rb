require "time"

module ApplicationHelper
  def format_tweet_created_at(dt)
    dt.to_time.localtime("+09:00").strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_tweet_text(text)
    text
      .gsub(/<url:((?:https?|ftp).+?):(.+?)>/){link_to($2, $1, :target => "_blank")}
      .gsub(/<hashtag:(.+?)>/){link_to("##{$1}", "https://twitter.com/search?q=%23#{$1}")}
      .gsub(/<mention:(.+?)>/){link_to("@#{$1}", "/#{$1}")}
      .gsub(/\r\n|\r|\n/, "<br />")
  end

  def format_source_text(text)
    text
  end

  def status_url(tweet)
    "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
  end

  def user_url(user)
    "/#{user.screen_name}"
  end
end
