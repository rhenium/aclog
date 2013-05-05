# -*- coding: utf-8 -*-
require "em-twitter"
require "yajl"
require "msgpack"
require "./settings"
require "./logger"

class Worker
  class DBProxyClient < EM::Connection
    def send_object(data)
      send_data(data.to_msgpack)
    end

    def initialize
      @clients = {}
      @pac = MessagePack::Unpacker.new
      @excludes = []
    end

    def escape_colon(str); str.gsub(":", "%3A").gsub("<", "%3C").gsub(">", "%3E"); end

    def format_text(status)
      chars = status[:text].to_s.split(//)

      entities = status[:entities].map{|k, v| v.map{|n| n.update(:type => k)}}.flatten.sort_by{|entity| entity[:indices].first}

      result = []
      last_index = entities.inject(0) do |last_index, entity|
        result << chars[last_index...entity[:indices].first]
        case entity[:type]
        when :urls, :media
          result << "<url:#{escape_colon(entity[:expanded_url])}:#{escape_colon(entity[:display_url])}>"
        when :hashtags
          result << "<hashtag:#{escape_colon(entity[:text])}>"
        when :user_mentions
          result << "<mention:#{escape_colon(entity[:screen_name])}>"
        when :symbols
          result << "<symbol:#{escape_colon(entity[:text])}>"
        end

        entity[:indices].last
      end
      result << chars[last_index..-1]

      result.flatten.join
    end

    def format_source(status)
      if status[:source].index("<a")
        url = status[:source].scan(/href="(.+?)"/).flatten.first
        name = status[:source].scan(/>(.+?)</).flatten.first
        "<url:#{escape_colon(url)}:#{escape_colon(name)}>"
      else
        status[:source]
      end
    end

    def favbot?(source, target_object)
      favs = source[:favourites_count]
      tweets = source[:statuses_count]
      bio = source[:description]
      name = source[:name]
      # えたふぉ
      if (Time.now - Time.parse(target_object[:created_at])) < 2
        case
        when
          (tweets < 1000 && favs > tweets * 2),
          (source[:friends_count] > source[:followers_count] * 10 && favs > tweets)
          return true
        end
      end
      if
        case
        when
          favs > tweets * 30,
          (tweets < 100 && favs > tweets * 2),
          (source[:default_profile_image] == true && favs > tweets * 2)
          return true
        end
      end

      false
    end

    def bot?(status)
      sources = [
        /^<a href="http:\/\/twittbot\.net\/" rel="nofollow">twittbot\.net<\/a>$/,
        /^<a href="http:\/\/botmaker\.dplays\.net\/" rel="nofollow">BotMaker<\/a>$/,
        /^<a href="http:\/\/makebot\.sh\/" rel="nofollow">makebot\.sh( [0-9])?<\/a>$/,
        /^<a href="http:\/\/lbattery\.dip\.jp\/twihaialert\/" rel="nofollow">ツイ廃あらーと<\/a>$/,
        /^<a href="http:\/\/app\.xmgn\.com\/tweetcounter\/" rel="nofollow">ツイート数カウントくん<\/a>$/,
        /^<a href="http:\/\/gumu-lab\.com\/replychecker\/" rel="nofollow">リプライ数チェッカ<\/a>$/,
        /^<a href="http:\/\/bit.ly\/SiHFe6" rel="nofollow">劣化コピー<\/a>$/,
      ]
      sources.any?{|r| r =~ status[:source]}
    end

    def send_spam(user)
      send_object({
        type: "spam",
        id: user[:id]
      })
    end

    def send_user(user)
      send_object({
        :type => "user",
        :id => user[:id],
        :screen_name => user[:screen_name],
        :name => user[:name],
        :profile_image_url => user[:profile_image_url_https],
        :protected => user[:protected]
      })
    end

    def send_tweet(status)
      unless bot?(status)
        send_user(status[:user])
        send_object({
          :type => "tweet",
          :id => status[:id],
          :text => format_text(status),
          :source => format_source(status),
          :tweeted_at => status[:created_at],
          :user_id => status[:user][:id]
        })
      end
    end

    def send_favorite(source, target_object)
      if @excludes.include?(source[:id])
        # ignored
      else
        if favbot?(source, target_object)
          # ignored
          send_spam(source)
          $logger.info("Add #{source[:screen_name]}(##{source[:id]}) to ignore list")
          @excludes << source[:id]
        elsif !bot?(target_object)
          send_tweet(target_object)
          send_user(source)
          send_object({
            :type => "favorite",
            :tweet_id => target_object[:id],
            :user_id => source[:id]
          })
        end
      end
    end

    def send_unfavorite(source, target_object)
      send_object({
        :type => "delete",
        :tweet_id => target_object[:id],
        :user_id => source[:id]
      })
    end

    def send_retweet(status)
      unless bot?(status[:retweeted_status])
        send_tweet(status[:retweeted_status])
        send_user(status[:user])
        send_object({
          :type => "retweet",
          :id => status[:id],
          :tweet_id => status[:retweeted_status][:id],
          :user_id => status[:user][:id]
        })
      end
    end

    def send_delete(deleted_status_id, deleted_user_id)
      send_object({
        :type => "delete",
        :id => deleted_status_id,
        :user_id => deleted_user_id
      })
    end
    ### end - send to receiver

    def receive_account(msg)
      user_id = msg["user_id"]
      account_id = msg["id"]

      conopts = {:host => "userstream.twitter.com",
                 :path => "/1.1/user.json",
                 :oauth => {
                   :consumer_key => Settings.consumer[msg["consumer_version"].to_i].key,
                   :consumer_secret => Settings.consumer[msg["consumer_version"].to_i].secret,
                   :token => msg["oauth_token"],
                   :token_secret => msg["oauth_token_secret"]},
                 :method => "GET"}
      if @clients[account_id]
        unless @clients[account_id].options[:oauth][:token] == conopts[:oauth][:token]
          @clients[account_id].connection.update(conopts)
          $logger.info("Updated(##{account_id}/#{user_id}/#{msg["consumer_version"].to_i})")
        else
          $logger.info("Not Updated(##{account_id}/#{user_id}/#{msg["consumer_version"].to_i})")
        end
        return
      end
      @clients[account_id] = client = EM::Twitter::Client.new(conopts)

      client.on_error do |message|
        $logger.warn("Unknown Error(##{account_id}/#{user_id}): #{message}")
      end

      client.on_unauthorized do
        # revoked?
        $logger.warn("Unauthorized(##{account_id}/#{user_id})")
        out = {:type => "unauthorized", :user_id => user_id, :id => account_id}
        send_object(out)
        client.connection.stop
        @clients.delete(account_id)
      end

      client.on_enhance_your_calm do
        # limit?
        $logger.warn("Enhance your calm(##{account_id}/#{user_id})")
      end

      client.on_no_data_received do
        # (?)
        $logger.warn("No data received(##{account_id}/#{user_id})")
        client.close_connection
      end

      client.each do |chunk|
        begin
          hash = Yajl::Parser.parse(chunk, :symbolize_keys => true)
        rescue Yajl::ParseError
          $logger.warn("Unexpected chunk(##{account_id}/#{user_id}): #{chunk}")
          next
        end

        if hash[:warning]
          $logger.info("Stall warning(##{account_id}/#{user_id}): #{hash[:warning]}")
        elsif hash[:delete] && hash[:delete][:status]
          deleted_status_id = hash[:delete][:status][:id]
          deleted_user_id = hash[:delete][:status][:user_id]
          send_delete(deleted_status_id, deleted_user_id)
          $logger.debug("Delete(##{account_id}/#{user_id}): #{deleted_user_id} => #{deleted_status_id}")
        elsif hash[:limit]
          $logger.warn("UserStreams Limit Event(##{account_id}/#{user_id}): #{hash[:limit][:track]}")
        elsif hash[:event]
          case hash[:event]
          when "favorite"
            source = hash[:source]
            target_object = hash[:target_object]
            if target_object && target_object[:user] &&
              (!target_object[:user][:protected] ||
                target_object[:user][:id] == user_id)
              send_favorite(source, target_object)
              $logger.debug("Favorite(##{account_id}/#{user_id}): #{source[:screen_name]} => #{target_object[:id]}")
            end
          when "unfavorite"
            send_unfavorite(hash[:source], hash[:target_object])
            $logger.debug("Unfavorite(##{account_id}/#{user_id}): #{hash[:source][:screen_name]} => #{hash[:target_object][:id]}")
          end
        elsif hash[:user]
          # tweet
          if hash[:retweeted_status]
            if hash[:retweeted_status][:user][:id] == user_id || hash[:user][:id] == user_id
              send_retweet(hash)
              $logger.debug("Retweet(##{account_id}/#{user_id}): #{hash[:user][:screen_name]} => #{hash[:retweeted_status][:id]}")
            end
          elsif hash[:user][:id] == user_id
            # update: exclude not favorited tweet
            send_tweet(hash)
            $logger.debug("Tweet(##{account_id}/#{user_id}): #{hash[:user][:screen_name]} => #{hash[:id]}")
          end
        elsif hash[:friends]
          # monyo
        else
          $logger.debug("??(##{account_id}/#{user_id})")
        end
      end

      client.on_reconnect do |timeout, retries|
        $logger.warn("Reconnected(##{account_id}/#{user_id}): #{retries}")
      end

      client.on_max_reconnects do |timeout, retries|
        $logger.warn("Max reconnects(##{account_id}/#{user_id}): #{retries}")
        client.connection.stop
        @clients.delete(account_id)
      end

      client.connect
      $logger.info("Connected(##{account_id}/#{user_id}/#{msg["consumer_version"].to_i})")
    end

    def post_init
      out = {:type => "init",
             :secret_key => Settings.secret_key,
             :worker_number => Settings.worker_number}
      send_object(out)
    end

    def unbind
      $logger.info("Connection closed")
      EM.add_timer(10) do
        reconnect(Settings.receiver_host, Settings.receiver_port)
        post_init
      end
    end

    def receive_data(data)
      @pac.feed_each(data) do |msg|
        unless msg.is_a?(Hash) && msg["type"]
          $logger.warn("Unknown data: #{msg}")
          return
        end

        case msg["type"]
        when "ok"
          $logger.info("ok: #{msg["message"]}")
        when "error"
          $logger.info("error: #{msg["message"]}")
        when "fatal"
          $logger.info("fatal: #{msg["message"]}")
        when "bye"
          $logger.info("bye: #{msg["message"]}")
        when "account"
          begin
            receive_account(msg)
          rescue
            $logger.error($!)
            $logger.error($@)
          end
        else
          $logger.info("Unknown message type: #{msg}")
        end
      end
    end

    def stop_all
      @clients.map{|k, v| v.connection.stop}
      send_object({:type => "quit", :reason => "stop_all"})
    end
  end

  def initialize
    $logger = Aclog::Logger.new(:info)
  end

  def start
    $logger.info("Worker ##{Settings.worker_number} started")
    EM.run do
      connection = EM.connect(Settings.receiver_host, Settings.receiver_port, DBProxyClient)

      stop = Proc.new do
        connection.stop_all
        EM.stop
      end
      Signal.trap(:INT, &stop)
      Signal.trap(:TERM, &stop)
    end
  end
end


