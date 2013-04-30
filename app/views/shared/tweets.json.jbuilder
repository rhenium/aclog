json.array! @tweets do |json, tweet|
  json.partial! "shared/partial/tweet", tweet: tweet
end

