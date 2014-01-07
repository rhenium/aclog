atom_feed do |feed|
  feed.title yield :title
  feed.subtitle yield :caption
  feed.updated DateTime.now

  @tweets.each do |tweet|
    feed.entry(tweet) do |entry|
      entry.title "#{tweet.favorites_count}/#{tweet.retweets_count}: #{CGI.unescapeHTML(strip_tags(format_tweet_text(tweet.text)))}"
      entry.updated Time.now.iso8601
      entry.summary "Has been favorited by #{tweet.favorites_count} #{tweet.favorites_count != 1 ? "people" : "person"}, " +
        "retweeted by #{tweet.retweets_count} #{tweet.retweets_count != 1 ? "people" : "person"}."
      entry.author do |author|
        author.name "#{tweet.user.name} (@#{tweet.user.screen_name})"
        author.uri tweet.user.twitter_url
      end
    end
  end
end

