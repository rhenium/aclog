class UserConnection
  def initialize(msg)
    @user_id = msg[:user_id]
    @account_id = msg[:id]
    @client = setup_client(msg)
  end

  def start
    @client.connect
    log(:debug, "start")
  end

  def update(hash)
    if @client.update_if_necessary(setup_options(hash))
      log(:debug, "update")
    else
      log(:debug, "no change")
    end
  end

  def stop
    @client.stop
    log(:debug, "stop")
  end

  private
  def setup_client(msg)
    client = UserStream::Client.new(setup_options(msg))

    client.on_error do |error|
      case error
      when Errno::ETIMEDOUT
        log(:warn, "Stalled")
        EM.add_timer(5) { client.reconnect }
      when Errno::ECONNRESET
        log(:warn, "Connection reset")
        EM.add_timer(5) { client.reconnect }
      else
        log(:error, "Unknown error: #{error}")
      end
    end
    client.on_service_unavailable do |message|
      log(:info, "Service unavailable")
      EM.add_timer(10) { client.reconnect }
    end
    client.on_unauthorized do |message|
      log(:info, "Unauthorized")
      EventChannel << { event: :unauthorized,
                        data: { id: msg[:id], user_id: msg[:user_id] } }
      stop
    end
    client.on_enhance_your_calm do |message|
      log(:warn, "enhance_your_calm: #{message}")
      EM.add_timer(60) { client.reconnect }
    end
    client.on_disconnected do
      log(:warn, "disconnected")
      EM.add_timer(5) { client.reconnect }
    end

    client.on_item do |json|
      begin
        if json[:friends]
          log(:info, "Connection established (friends: #{json[:friends]&.size})")
        elsif json.dig(:delete, :status)
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
        log(:error, "Item processing error: (#{e}): #{json}")
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

  def on_user(json, timestamp)
    log(:debug, "user-#{json[:id]} (#{timestamp})") if $VERBOSE
    EventChannel << { event: :user,
                      identifier: "user-#{json[:id]}",
                      version: timestamp,
                      data: compact_user(json) }
  end

  def on_tweet(json, timestamp = nil)
    timestamp ||= json[:timestamp_ms].to_i
    log(:debug, "tweet-#{json[:id]} (#{timestamp})") if $VERBOSE
    on_user(json[:user], timestamp)
    EventChannel << { event: :tweet,
                      identifier: "tweet-#{json[:id]}",
                      version: timestamp,
                      data: compact_tweet(json) }
  end

  def on_retweet(json)
    log(:debug, "retweet-#{json[:id]}") if $VERBOSE
    timestamp_ = json[:timestamp_ms].to_i
    on_user(json[:user], timestamp_)
    on_tweet(json[:retweeted_status], timestamp_)
    EventChannel << { event: :retweet,
                      identifier: "retweet-#{json[:id]}",
                      version: 0,
                      data: { id: json[:id],
                              user: { id: json.dig(:user, :id) },
                              retweeted_status: { id: json.dig(:retweeted_status, :id),
                                                  user: { id: json.dig(:retweeted_status, :user, :id) } } } }
  end

  def on_event_tweet(json)
    timestamp = (json[:timestamp_ms] || (Time.parse(json[:created_at]).to_i * 1000)).to_i
    log(:debug, "#{json[:event]}-#{json.dig(:source, :id)}-#{json.dig(:target_object, :id)} (#{timestamp})") if $VERBOSE
    on_user(json[:source], timestamp)
    on_user(json[:target], timestamp)
    on_tweet(json[:target_object], timestamp)
    EventChannel << { event: json[:event].to_sym,
                      identifier: "#{json[:event]}-#{json.dig(:source, :id)}-#{json.dig(:target_object, :id)}",
                      version: timestamp,
                      data: { source: { id: json.dig(:source, :id) },
                              target: { id: json.dig(:target, :id) },
                              target_object: { id: json.dig(:target_object, :id) } } }
  end

  def on_delete(json)
    log(:debug, "delete-#{json.dig(:delete, :status, :id)}") if $VERBOSE
    EventChannel << { event: :delete,
                      identifier: "delete-#{json.dig(:delete, :status, :id)}",
                      version: 0,
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
      user: { id: status.dig(:user, :id) } }
  end

  def log(level, message)
    WorkerNode.logger.__send__(level, "##{@account_id}/#{@user_id}") { message }
  end
end
