module TweetsHelper
  def favorites_truncate_count
    params[:full] == "true" ? Settings.tweets.favorites.max : Settings.tweets.favorites.default
  end

  def favorites_truncated?(tweet)
    (favorites_truncate_count || Float::INFINITY) < [tweet.favorites_count, tweet.retweets_count].max
  end

  def format_tweet_text(text)
    text = sanitize(text)
    text = auto_link(text, suppress_lists: true, username_include_symbol: true, username_url_base: "/")
    text.gsub(/\r\n|\r|\n/, "<br />").html_safe
  end

  def link_to_source_text(source)
    if /^<a href="(.+?)" rel="nofollow">(.+?)<\/a>/ =~ source
      link_to $2, $1
    else
      source
    end
  end
end
