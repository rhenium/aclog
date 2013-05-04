json.array! @tweets do |json, tweet|
  json.partial! "tweet", tweet: tweet
end

