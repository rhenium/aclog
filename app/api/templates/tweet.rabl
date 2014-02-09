object @tweet

attributes :id, :user_id, :favorites_count, :retweets_count
node(:favoriters) {|obj| obj.favoriters.pluck(:user_id) }
node(:retweeters) {|obj| obj.retweeters.pluck(:user_id) }

