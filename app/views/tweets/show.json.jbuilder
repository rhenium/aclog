json.next nil
json.prev nil

json.statuses do
  @tweet.reply_ancestors(2).each do |tweet|
    json.child! do
      json.partial! "tweet", tweet: tweet
      json.aside true
    end
  end
  json.child! do
    json.partial! "tweet", tweet: @tweet
  end
  @tweet.reply_descendants(2).each do |tweet|
    json.child! do
      json.partial! "tweet", tweet: tweet
      json.aside true
    end
  end
end
