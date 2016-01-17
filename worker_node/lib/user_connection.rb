class UserConnection
  def initialize(msg)
    @user_id = msg[:user_id]
    @account_id = msg[:id]
    @client = setup_client(msg)
  end

  def start
    @client.connect
    log(:debug, "Connect")
  end

  def update(hash)
    if @client.update_if_necessary(setup_options(hash))
      log(:info, "Updated connection")
    else
      log(:debug, "Token not changed")
    end
  end

  def stop
    @client.stop
    log(:info, "Stop: #{@account_id}")
  end

  private
  def setup_client(msg)
    client = UserStream::Client.new(setup_options(msg))

    client.on_error do |error|
      if error == Errno::ETIMEDOUT
        log(:warn, "Stalled")
        EM.add_timer(5) { client.reconnect }
      elsif error = Errno::ECONNRESET
        log(:warn, "Connection reset")
        EM.add_timer(5) { client.reconnect }
      else
        log(:error, "Unknown error: #{error}")
      end
    end
    client.on_service_unavailable do |message|
      log(:warn, "Service unavailable")
      EM.add_timer(60) { client.reconnect }
    end
    client.on_unauthorized do |message|
      log(:warn, "Unauthorized")
      EventChannel << { event: :unauthorized,
                        data: { id: msg[:id], user_id: msg[:user_id] } }
      stop
    end
    client.on_enhance_your_calm do |message|
      log(:warn, "420: #{message}")
      EM.add_timer(60) { client.reconnect }
    end
    client.on_disconnected do
      log(:warn, "Disconnected")
      EM.add_timer(5) { client.reconnect }
    end

    client.on_item do |json|
      begin
        if json[:friends]
          log(:info, "Connection established (friends: #{json[:friends].size})")
        elsif json[:delete] && json[:delete][:status]
          on_delete(json)
        elsif json[:event] == "favorite" || json[:event] == "unfavorite"
          on_event_tweet(json)
        elsif json[:user] && json[:retweeted_status]
          on_retweet(json)
        elsif json[:user]
          on_tweet(json)
        elsif json[:warning]
          log(:info, "warning: #{json[:warning]}")
        else
          # scrub_geo, limit, unknown message
        end
      rescue => e
        log(:warn, "Item processing error: (#{e}): #{json}")
      end
    end

    client
  end

  def setup_options(msg)
    {
      oauth: {
        consumer_key: msg[:consumer_key],
        consumer_secret: msg[:consumer_secret],
        access_token: msg[:oauth_token],
        access_token_secret: msg[:oauth_token_secret]
      },
      params: Settings.user_stream_params,
      compression: Settings.user_stream_compression,
      identifier: "##{msg[:id]}/#{msg[:user_id]}"
    }
  end

  def on_user(json, timestamp = nil)
    log(:debug, "user-#{json[:id]} (#{timestamp})")
    EventChannel << { event: :user,
                      identifier: "user-#{json[:id]}",
                      version: timestamp,
                      data: compact_user(json) }
  end

  def on_tweet(json, timestamp = nil)
    timestamp ||= json[:timestamp_ms].to_i
    log(:debug, "tweet-#{json[:id]} (#{timestamp})")
    on_user(json[:user], timestamp)
    EventChannel << { event: :tweet,
                      identifier: "tweet-#{json[:id]}",
                      version: timestamp,
                      data: compact_tweet(json) }
  end

  def on_retweet(json, timestamp = nil)
    timestamp ||= json[:timestamp_ms].to_i
    log(:debug, "retweet-#{json[:id]} (#{timestamp})")
    on_user(json[:user], timestamp)
    on_tweet(json[:retweeted_status], timestamp)
    EventChannel << { event: :retweet,
                      identifier: "retweet-#{json[:id]}",
                      version: timestamp,
                      data: { id: json[:id],
                              user: { id: json[:user][:id] },
                              retweeted_status: { id: json[:retweeted_status][:id],
                                                  user: { id: json[:retweeted_status][:user][:id] } } } }
  end

  def on_event_tweet(json, timestamp = nil)
    timestamp ||= (json[:timestamp_ms] || (Time.parse(json[:created_at]).to_i * 1000)).to_i
    log(:debug, "#{json[:event]}-#{json[:source][:id]}-#{json[:target_object][:id]} (#{timestamp})")
    on_user(json[:source], timestamp)
    on_user(json[:target], timestamp)
    on_tweet(json[:target_object], timestamp)
    EventChannel << { event: json[:event].to_sym,
                      identifier: "#{json[:event]}-#{json[:source][:id]}-#{json[:target_object][:id]}",
                      version: timestamp,
                      data: { source: { id: json[:source][:id] },
                              target: { id: json[:target][:id] },
                              target_object: { id: json[:target_object][:id] } } }
  end

  def on_delete(json, timestamp = nil)
    timestamp ||= json[:timestamp_ms].to_i
    log(:debug, "delete-#{json[:delete][:status][:id]} (#{timestamp})")
    EventChannel << { event: :delete,
                      identifier: "delete-#{json[:delete][:status][:id]}",
                      version: timestamp,
                      data: json }
  end

  def compact_user(user)
    { id: user[:id],
      screen_name: user[:screen_name],
      name: user[:name],
      profile_image_url_https: user[:profile_image_url_https],
      protected: user[:protected] }
  end

  def compact_tweet(status)
    { id: status[:id],
      text: status[:text],
      entities: status[:entities],
      extended_entities: status[:extended_entities],
      source: status[:source],
      created_at: status[:created_at],
      in_reply_to_status_id: status[:in_reply_to_status_id],
      favorite_count: (status[:favorite_count] || 0),
      retweet_count: (status[:retweet_count] || 0),
      user: { id: status[:user][:id] } }
  end

  def log(level, message)
    WorkerNode.logger.__send__(level, "##{@account_id}/#{@user_id}") { message }
  end
end
