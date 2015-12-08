atom_feed(root_url: url_for(params.merge(format: nil, only_path: false))) do |feed|
  feed.title "@#{@user.screen_name}'s Timeline - aclog"
  feed.subtitle "@#{@user.screen_name}'s Timeline - aclog"
  feed.updated DateTime.now

  @tweets.each do |tweet|
    feed.entry(tweet, url: "#{root_url}i/#{tweet.id}") do |entry|
      entry.title "#{tweet.favorites_count}/#{tweet.retweets_count}: #{CGI.unescapeHTML(tweet.text)}"
      entry.updated Time.now.iso8601
      entry.summary "Has been favorited by #{tweet.favorites_count} #{tweet.favorites_count != 1 ? "people" : "person"}, " +
        "retweeted by #{tweet.retweets_count} #{tweet.retweets_count != 1 ? "people" : "person"}."
      entry.author do |author|
        author.name "#{tweet.user.name} (@#{tweet.user.screen_name})"
        author.uri "https://twitter.com/#{tweet.user.screen_name}"
      end
    end
  end
end
