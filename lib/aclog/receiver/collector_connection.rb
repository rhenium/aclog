# -*- coding: utf-8 -*-
require "time"

module Aclog
  module Receiver
    class CollectorConnection < EM::Connection
      def initialize(connections)
        @connections = connections

        @worker_number = nil
        @pac = MessagePack::Unpacker.new

        unless defined? @@queue
          @@queue = EM::Queue.new

          _cr = -> bl { bl.call; @@queue.pop &_cr }
          EM.defer { @@queue.pop &_cr }
        end

        @@saved_tweets ||= []
      end

      def send_account(account)
        send_object(
          type: "account",
          id: account.id,
          oauth_token: account.oauth_token,
          oauth_token_secret: account.oauth_token_secret,
          user_id: account.user_id,
          consumer_version: account.consumer_version)
        Rails.logger.debug("Sent #{account.id}/#{account.user_id}")
      end

      def post_init
        # なにもしない。クライアントが
      end

      def unbind
        Rails.logger.info("Connection closed(#{@worker_number})")
        @connections.delete_if{|k, v| v == self}
      end

      def receive_data(data)
        @pac.feed_each(data) do |msg|
          unless msg.is_a?(Hash) && msg["type"]
            Rails.logger.warn("Unknown data: #{msg}")
            send_object(type: "fatal", message: "Unknown data")
            close_connection_after_writing
            return
          end

          if not @authorized and not msg["type"] == "init"
            Rails.logger.warn("Not authorized client: #{msg}")
            send_object(type: "fatal", message: "You aren't authorized")
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
          when "spam"
            receive_spam(msg)
          when "quit"
            Rails.logger.info("Quit(#{@worker_number}): #{msg["reason"]}")
            send_data(type: "quit", message: "Bye")
            close_connection_after_writing
          else
            Rails.logger.warn("Unknown message type(#{@worker_number}): #{msg["type"]}")
            send_object(type: "error", message: "Unknown message type: #{msg["type"]}")
          end
        end
      end

      private
      def send_object(data)
        send_data(data.to_msgpack)
      end

      def receive_init(msg)
        secret_key = msg["secret_key"]
        worker_number = msg["worker_number"]
        unless secret_key == Settings.secret_key
          Rails.logger.warn("Invalid secret_key(?:#{worker_number}): \"#{secret_key}\"")
          send_object(type: "fatal", message: "Invalid secret_key")
          close_connection_after_writing
          return
        end
        if worker_number > Settings.worker_count
          Rails.logger.warn("Invalid worker_number: #{worker_number}, secret_key: \"#{secret_key}\"")
          send_object(type: "fatal", message: "Invalid worker_number")
          close_connection_after_writing
          return
        end

        if @connections[worker_number]
          @connections[worker_number].close_connection
        end
        @connections[worker_number] = self
        @worker_number = worker_number
        @authorized = true
        Rails.logger.info("Connected(#{@worker_number})")
        send_object(type: "ok", message: "Connected")

        Account.where("id % ? = ?", Settings.worker_count, @worker_number).each do |account|
          send_account(account)
        end
      end

      def receive_unauthorized(msg)
        Rails.logger.warn("Unauthorized(#{@worker_number}): #{msg["user_id"]}")
        # unregister
      end

      def receive_user(msg)
        @@queue.push -> do
          Rails.logger.debug("Received User(#{@worker_number}): #{msg["id"]}")
          User.from_hash(:id => msg["id"],
                         :screen_name => msg["screen_name"],
                         :name => msg["name"],
                         :profile_image_url => msg["profile_image_url"],
                         :protected => msg["protected"])
        end
      end

      def receive_tweet(msg)
        @@queue.push -> do
          Rails.logger.debug("Received Tweet(#{@worker_number}): #{msg["id"]}")
          unless @@saved_tweets.include?(msg["id"])
            @@saved_tweets << msg["id"]
            if @@saved_tweets.size > 100000
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
        @@queue.push -> do
          Rails.logger.debug("Receive Favorite(#{@worker_number}): #{msg["user_id"]} => #{msg["tweet_id"]}")
          f = Favorite.from_hash(:tweet_id => msg["tweet_id"],
                                 :user_id => msg["user_id"])
          if t = Tweet.find_by(id: msg["tweet_id"])
            t.notify_favorite
          end
        end
      end

      def receive_retweet(msg)
        @@queue.push -> do
          Rails.logger.debug("Receive Retweet(#{@worker_number}): #{msg["user_id"]} => #{msg["tweet_id"]}")
          Retweet.from_hash(:id => msg["id"],
                            :tweet_id => msg["tweet_id"],
                            :user_id => msg["user_id"])
        end
      end

      def receive_delete(msg)
        @@queue.push -> do
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

      def receive_spam(msg)
        Rails.logger.info("Receive Spam(#{@worker_number}): #{msg["id"]}")
        # @@queue.push -> do
        #   # TODO
        # end
      end
    end
  end
end

