module ApplicationHelper
  def format_tweet_created_at(dt)
    dt.to_s
  end

  def format_tweet_text(text)
    text
      .gsub(/<url:((?:https?|ftp).+?):(.+?)>/){link_to($2, $1, :target => "_blank")}
      .gsub(/<hashtag:(.+?)>/){link_to("##{$1}", "https://twitter.com/search?q=%23#{$1}")}
      .gsub(/<mention:(.+?)>/){link_to("@#{$1}", "/#{$1}")}
  end
end
