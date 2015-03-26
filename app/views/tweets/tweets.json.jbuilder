json.next @next_url
json.prev @prev_url

json.statuses @tweets, partial: "tweet", as: :tweet
