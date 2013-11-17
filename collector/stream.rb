# -*- coding: utf-8 -*-
require "em-twitter"
require "yajl"
require "./settings"
require "./helper"

module Aclog
  module Collector
    class Stream
      include Aclog::Collector::Helper
      attr_reader :client
      attr_accessor :logger

      def initialize(logger, callback, hash)
        @logger = logger
        @user_id = hash["user_id"]
        @account_id = hash["id"]
        @callback = callback
        ready_client(hash)
      end

      def ready_client(hash)
        @client = EM::Twitter::Client.new(gopts(hash))
        @client.on_error {|message|
          log(:error, "Unknown Error", message) }
        @client.on_enhance_your_calm {
          log(:warn, "Enhance your calm") }
        @client.on_no_data_received {
          log(:warn, "No data received") }
        @client.on_reconnect {|timeout, retries|
          log(:warn, "Reconnected", retries) }
        @client.on_max_reconnects {|timeout, retries|
          @client.connection.stop
          log(:warn, "Reached max reconnects", retries) }
        @client.on_unauthorized {
          log(:warn, "Unauthorized")
          @client.connection.stop
          @callback.call(type: "unauthorized", user_id: @user_id, id: @account_id) }
        @client.on_service_unavailable {
          # account deleted?
          log(:warn, "Service Unavailable")
          @client.connection.stop }

        @client.each do |chunk|
          begin
            hash = Yajl::Parser.parse(chunk, :symbolize_keys => true)
          rescue Yajl::ParseError
            log(:warn, "Unexpected chunk", chunk)
            next
          end

          if hash[:warning]
            log(:info, "Stall warning", hash[:warning])
          elsif hash[:delete]
            if d = hash[:delete][:status]
              send_delete(d[:id], d[:user_id])
            end
          elsif hash[:limit]
            log(:warn, "UserStreams Limit", hash[:limit][:track])
          elsif hash[:event]
            # event
            case hash[:event]
            when "favorite"
              send_favorite(hash[:source], hash[:target], hash[:target_object])
            when "unfavorite"
              send_unfavorite(hash[:source], hash[:target], hash[:target_object])
            end
          elsif hash[:user]
            # tweet
            if hash[:retweeted_status]
              if hash[:retweeted_status][:user][:id] == @user_id ||
                 hash[:user][:id] == @user_id
                send_retweet(hash)
              end
            elsif hash[:user][:id] == @user_id
              send_tweet(hash)
            end
          elsif hash[:friends]
            # maybe first message
            log(:debug, "Received friends", hash[:friends].size)
          elsif hash[:scrub_geo]
            log(:debug, "scrub_geo", hash)
          else
            log(:info, "Unexpected UserStreams data", hash)
          end
        end
        @client
      end

      def start
        @client.connect
        log(:info, "Connected")
      end

      def update(hash)
        opts = gopts(hash)
        if opts[:oauth][:token] != @client.options[:oauth][:token]
          @client.connection.update(opts)
          log(:info, "Connection updated")
        end
      end

      def stop
        @client.connection.stop
        log(:info, "Disconnected")
      end

      private
      def log(level, msg, data = nil)
        @logger.send(level, "#{msg}(##{@account_id}/#{@user_id}): #{data}")
      end

      def gopts(msg)
        {
          host: "userstream.twitter.com",
          path: "/1.1/user.json",
          params: {
            with: "user"
          },
          oauth: {
            consumer_key: Settings.consumer[msg["consumer_version"]].key,
            consumer_secret: Settings.consumer[msg["consumer_version"]].secret,
            token: msg["oauth_token"],
            token_secret: msg["oauth_token_secret"]},
          method: :get
        }
      end

      def conv_user(user)
        {id: user[:id],
         screen_name: user[:screen_name],
         name: user[:name],
         profile_image_url: user[:profile_image_url_https],
         protected: user[:protected]}
      end

      def conv_tweet(status)
        {type: "tweet",
         id: status[:id],
         text: format_text(status),
         source: format_source(status),
         tweeted_at: status[:created_at],
         in_reply_to_status_id: status[:in_reply_to_status_id],
         user: conv_user(status[:user])}
      end

      def send_tweet(status)
        @callback.call(conv_tweet(status))
        log(:debug, "Sent tweet", status[:id])
      end

      def send_favorite(source, target, target_object)
        @callback.call(type: "favorite",
                       tweet: conv_tweet(target_object),
                       user: conv_user(source))
        log(:debug, "Sent favorite", source[:id] => target_object[:id])
      end

      def send_unfavorite(source, target, target_object)
        @callback.call(type: "unfavorite",
                       tweet: conv_tweet(target_object),
                       user: conv_user(source))
        log(:debug, "Sent unfavorite", source[:id] => target_object[:id])
      end

      def send_retweet(status)
        @callback.call(type: "retweet",
                       id: status[:id],
                       tweet: conv_tweet(status[:retweeted_status]),
                       user: conv_user(status[:user]))
        log(:debug, "Sent retweet", status[:user][:id] => status[:retweeted_status][:id])
      end

      def send_delete(deleted_status_id, deleted_user_id)
        @callback.call(type: "delete",
                       id: deleted_status_id,
                       user_id: deleted_user_id)
        log(:debug, "Sent delete", deleted_user_id => deleted_status_id)
      end
    end
  end
end
