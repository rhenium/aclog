class UserConnection
  def initialize(msg)
    @user_id = msg[:user_id]
    @account_id = msg[:id]
    @client = UserStream::Client.new(msg.merge(params: Settings.user_stream_params, compression: Settings.user_stream_compression))
    setup_client
  end

  def start
    @client.connect
    log(:info, "Connected")
  end

  def update(hash)
    if hash[:oauth_token] == @client.options[:oauth_token]
      log(:debug, "Token is not changed")
    else
      @client.update(hash)
      log(:info, "Updated connection")
    end
  end

  def stop
    @client.close
    log(:info, "Stopped: #{@account_id}")
  end

  private
  def setup_client
    @client.on_error do |error|
      if error.is_a? Errno::ETIMEDOUT
        log(:warn, "Stalled")
        reconnect
      else
        log(:error, "Unknown error: #{error}")
      end
    end
    @client.on_service_unavailable do |message|
      # TODO: occurs when the Twitter account is deleted?
      log(:info, "Service unavailable")
      self.stop
    end
    @client.on_unauthorized do |message|
      log(:warn, "Unauthorized")
      EventChannel << { event: :unauthorized,
                        identifier: nil,
                        data: { id: @account_id, user_id: @user_id } }
      self.stop
    end
    @client.on_enhance_your_calm do |message|
      log(:warn, "420: #{message}")
    end
    @client.on_disconnected do
      @client.reconnect
    end

    @client.on_item do |item|
      begin
        json = Yajl::Parser.parse(item, symbolize_keys: true)
      rescue Yajl::ParseError
        log(:warn, "JSON parse error: #{item}")
        next
      end

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
    end
  end

  def on_user(json)
    log(:debug, "User: @#{json[:screen_name]} (#{json[:id]})")
    EventChannel << { event: :user,
                      identifier: "user-#{json[:id]}-#{json[:profile_image_url_https]}",
                      data: compact_user(json) }
  end

  def on_tweet(json)
    log(:debug, "Tweet: #{json[:user][:id]} => #{json[:id]}")
    EventChannel << { event: :tweet,
                      identifier: "tweet-#{json[:id]}-#{json[:favorite_count]}-#{json[:retweet_count]}",
                      data: compact_tweet(json) }
    on_user(json[:user])
  end

  def on_retweet(json)
    log(:debug, "Retweet: #{json[:user][:id]} => #{json[:retweeted_status][:id]}")
    EventChannel << { event: :retweet,
                      identifier: "retweet-#{json[:id]}",
                      data: { id: json[:id],
                              user: { id: json[:user][:id] },
                              retweeted_status: { id: json[:retweeted_status][:id] } } }
    on_user(json[:user])
    on_tweet(json[:retweeted_status])
  end

  def on_event_tweet(json)
    log(:debug, "Event: #{json[:event]}: #{json[:source][:screen_name]} => #{json[:target][:screen_name]}/#{json[:target_object][:id]}")
    EventChannel << { event: json[:event].to_sym,
                      identifier: "#{json[:event]}-#{json[:timestamp_ms]}-#{json[:source][:id]}-#{json[:target][:id]}-#{json[:target_object][:id]}",
                      data: {  timestamp_ms: json[:timestamp_ms],
                               source: { id: json[:source][:id] },
                               target: { id: json[:target][:id] },
                               target_object: { id: json[:target_object][:id] } } }
    on_user(json[:source])
    on_user(json[:target])
    on_tweet(json[:target_object])
  end

  def on_delete(json)
    log(:debug, "Delete: #{json[:delete][:status]}")
    EventChannel << { event: :delete,
                      identifier: "delete-#{json[:delete][:status][:id]}",
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
      source: status[:source],
      created_at: status[:created_at],
      in_reply_to_status_id: status[:in_reply_to_status_id],
      favorite_count: status[:favorite_count],
      retweet_count: status[:retweet_count],
      user: { id: status[:user][:id] } }
  end

  def log(level, message)
    WorkerNode.logger.__send__(level, "UserConnection(##{@account_id}/#{@user_id})") { message }
  end
end
