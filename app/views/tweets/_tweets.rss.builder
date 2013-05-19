xml.instruct! :xml
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title title
    xml.description caption
    xml.link url_for(rss: nil, only_path: false)
    xml.__send__(:"atom:link", rel: "self", href: request.url, type: "application/rss+xml")
    @tweets.each_with_index do |tweet, i|
      xml.item do
        xml.title "#{tweet.favorites_count}/#{tweet.retweets_count}: #{strip_tags(format_tweet_text(tweet.text))}"
        xml.description "Has been favorited by #{tweet.favorites_count} people, retweeted by #{tweet.retweets_count} people"
        xml.pubDate tweet.tweeted_at.rfc2822
        xml.link tweet_url(tweet.id)
        xml.guid tweet_url(tweet.id) + "#" + i.to_s
      end
    end
  end
end

