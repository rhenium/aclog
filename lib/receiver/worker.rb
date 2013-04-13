# -*- coding: utf-8 -*-
require "time"

module EM
  class Connection
    def send_object(data)
      send_data(data.to_msgpack)
    end
  end
end

class Receiver::Worker < DaemonSpawn::Base
  class DBProxyServer < EM::Connection
    def send_account_all
      Account.where("id % ? = ?", Settings.worker_count, @worker_number).each do |account|
        send_account(account)
      end
    end

    def send_account(account)
      out = {:type => "account",
             :id => account.id,
             :oauth_token => account.oauth_token,
             :oauth_token_secret => account.oauth_token_secret,
             :user_id => account.user_id,
             :consumer_version => account.consumer_version.to_i}
      send_object(out)
      Rails.logger.debug("Sent #{account.id}/#{account.user_id}")
    end

    def self.send_account(account)
      if con = @@connections[account.id % Settings.worker_count]
        con.send_account(account)
      end
    end

    def initialize
      @@connections ||= {}

      @worker_number = nil
      @pac = MessagePack::Unpacker.new

      @@saved_tweets ||= []
      unless defined?(@@wq)
        @@wq = EM::Queue.new  # ふぁぼ以外
        EM.defer do
          wcb = -> msg{msg.call; @@wq.pop &wcb}
          @@wq.pop &wcb
        end

        @@nq = EM::Queue.new # 通知するやつ（ふぁぼ）
        EM.defer do
          ncb = -> msg{msg.call; @@nq.pop &ncb}
          @@nq.pop &ncb
        end
      end
    end

    def post_init
      # なにもしない。クライアントが
    end

    def unbind
      Rails.logger.info("Connection closed(#{@worker_number})")
      @@connections.delete_if{|k, v| v == self}
    end

    def receive_data(data)
      @pac.feed_each(data) do |msg|
        unless msg.is_a?(Hash) && msg["type"]
          Rails.logger.warn("Unknown data: #{msg}")
          send_object({:type => "fatal", :message => "Unknown data"})
          close_connection_after_writing
          return
        end

        if msg["type"] != "init" && !@authorized
          Rails.logger.warn("Not authorized client: #{msg}")
          send_object({:type => "fatal", :message => "You aren't authorized"})
          close_connection_after_writing
          return
        end

        case msg["type"]
        when "init"
          receive_init(msg)
        when "unauthorized"
          receive_unauthorized(msg)
        when "user"
          receive_user(msg)
        when "tweet"
          receive_tweet(msg)
        when "favorite"
          receive_favorite(msg)
        when "retweet"
          receive_retweet(msg)
        when "delete"
          receive_delete(msg)
        when "quit"
          # Heroku の cycling など
          Rails.logger.info("Quit(#{@worker_number}): #{msg["reason"]}")
          send_data({:type => "quit", :message => "Bye"})
          close_connection_after_writing
        else
          Rails.logger.warn("Unknown message type(#{@worker_number}): #{msg["type"]}")
          send_object({:type => "error", :message => "Unknown message type: #{msg["type"]}"})
        end
      end
    end

    def receive_init(msg)
      secret_key = msg["secret_key"]
      worker_number = msg["worker_number"]
      unless secret_key == Settings.secret_key
        Rails.logger.warn("Invalid secret_key(?:#{worker_number}): \"#{secret_key}\"")
        send_object({:type => "fatal", :message => "Invalid secret_key"})
        close_connection_after_writing
        return
      end
      if worker_number > Settings.worker_count
        Rails.logger.warn("Invalid worker_number: #{worker_number}, secret_key: \"#{secret_key}\"")
        send_object({:type => "fatal", :message => "Invalid worker_number"})
        close_connection_after_writing
        return
      end
      if @@connections[worker_number]
        @@connections[worker_number].close_connection
      end
      @@connections[worker_number] = self
      @worker_number = worker_number
      @authorized = true
      Rails.logger.info("Connected(#{@worker_number})")
      send_object({:type => "ok", :message => "Connected"})
      send_account_all
    end

    def receive_unauthorized(msg)
      Rails.logger.warn("Unauthorized(#{@worker_number}): #{msg["user_id"]}")
      # unregister
    end

    def receive_user(msg)
      @@wq.push -> do
        Rails.logger.debug("Received User(#{@worker_number}): #{msg["id"]}")
        User.from_hash(:id => msg["id"],
                       :screen_name => msg["screen_name"],
                       :name => msg["name"],
                       :profile_image_url => msg["profile_image_url"],
                       :protected => msg["protected"])
      end
    end

    def receive_tweet(msg)
      @@wq.push -> do
        Rails.logger.debug("Received Tweet(#{@worker_number}): #{msg["id"]}")
        unless @@saved_tweets.include?(msg["id"])
          @@saved_tweets << msg["id"]
          if @@saved_tweets.size > 10000
            Rails.logger.debug("Tweet id dropped from cache: #{@@saved_tweets.shift}")
          end

          Tweet.from_hash(:id => msg["id"],
                          :text => msg["text"],
                          :source => msg["source"],
                          :tweeted_at => Time.parse(msg["tweeted_at"]),
                          :user_id => msg["user_id"])
        else
          Rails.logger.debug("Tweet already exists(#{@worker_number}): #{msg["id"]}")
        end
      end
    end

    def receive_favorite(msg)
      @@nq.push -> do
        Rails.logger.debug("Receive Favorite(#{@worker_number}): #{msg["user_id"]} => #{msg["tweet_id"]}")
        f = Favorite.from_hash(:tweet_id => msg["tweet_id"],
                               :user_id => msg["user_id"])
        if t = Tweet.cached(msg["tweet_id"])
          t.notify_favorite
        end
      end
    end

    def receive_retweet(msg)
      @@wq.push -> do
        Rails.logger.debug("Receive Retweet(#{@worker_number}): #{msg["user_id"]} => #{msg["tweet_id"]}")
        Retweet.from_hash(:id => msg["id"],
                          :tweet_id => msg["tweet_id"],
                          :user_id => msg["user_id"])
      end
    end

    def receive_delete(msg)
      @@wq.push -> do
        if msg["id"]
          Rails.logger.debug("Receive Delete(#{@worker_number}): #{msg["id"]}")
          Tweet.delete_from_id(msg["id"])
        elsif msg["tweet_id"]
          Rails.logger.debug("Receive Unfavorite(#{@worker_number}): #{msg["user_id"]} => #{msg["tweet_id"]}")
          Favorite.delete_from_hash(:tweet_id => msg["tweet_id"],
                                    :user_id => msg["user_id"])
        end
      end
    end
  end

  class RegisterServer < EM::Connection
    def initialize
      @pac = MessagePack::Unpacker.new
    end

    def post_init
    end

    def receive_data(data)
      @pac.feed_each(data) do |msg|
        p msg
        unless msg["type"]
          Rails.logger.error("Unknown message")
          send_object({:type => "fatal", :message => "Unknown message"})
          close_connection_after_writing
          return
        end

        case msg["type"]
        when "register"
          account = Account.where(:id => msg["id"]).first
          if account
            DBProxyServer.send_account(account)
            Rails.logger.info("Account registered and sent")
          else
            Rails.logger.error("Unknown account id")
            send_object({:type => "error", :message => "Unknown account id"})
          end
          close_connection_after_writing
        else
          Rails.logger.warn("Unknown register command: #{msg["type"]}")
        end
      end
    end
  end

  def initialize(opts = {})
    super(opts)
    _logger = Logger.new(STDOUT)
    _logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger = _logger
  end

  def start(args)
    Rails.logger.info("Database Proxy Started")
    EM.run do
      o = EM.start_server("0.0.0.0", Settings.db_proxy_port, DBProxyServer)
      i = EM.start_unix_domain_server(Settings.register_server_path, RegisterServer)

      stop = Proc.new do
        EM.stop_server(o)
        EM.stop_server(i)
        EM.stop
      end
      Signal.trap(:INT, &stop)
      Signal.trap(:QUIT, &stop)
      Signal.trap(:TERM, &stop)
    end
  end

  def stop
  end
end



