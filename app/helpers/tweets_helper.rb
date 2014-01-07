module TweetsHelper
  def favorites_truncate_count
    params[:full] == "true" ? Settings.tweets.favorites.max : Settings.tweets.favorites.default
  end

  def favorites_truncated?(tweet)
    (favorites_truncate_count || Float::INFINITY) < [tweet.favorites_count, tweet.retweets_count].max
  end

  def link_to_source_text(source)
    if /^<a href="(.+?)" rel="nofollow">(.+?)<\/a>/ =~ source
      link_to $2, $1
    elsif /^<url:(.+?)(?<!\\):(.+?)?>$/ =~ source
      link_to(*[$2, $1.gsub(/(https?)%3A/, "\\1:")].map {|m| m.gsub("\\:", ":") })
    else
      h source
    end
  end
end
