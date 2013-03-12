require "time"

module EM
  class Connection
    def send_chunk(data)
      send_data(data + "\r\n")
    end
  end
end

class Receiver::Worker
  class DBProxyServer < EM::Connection
    $worker_count = nil
    @@wq = EM::WorkQueue::WorkQueue.new do |arg|
      begin
        json = ::Yajl::Parser.parse(arg.last, :symbolize_keys => true)
      rescue ::Yajl::ParseError
        # JSON parse error....??
        p $!
      end

      case arg.first
      when "USER"
        $logger.debug("Received User")
        rec = User.find_or_initialize_by(:id => json[:id])
        rec.screen_name = json[:screen_name]
        rec.name = json[:name]
        rec.profile_image_url = json[:profile_image_url]
        rec.save! if rec.changed?
      when "TWEET"
        $logger.debug("Received Tweet")
        begin
          Tweet.create!(:id => json[:id],
                        :text => json[:text],
                        :source => json[:source],
                        :tweeted_at => Time.parse(json[:tweeted_at]),
                        :user_id => json[:user_id])
          $logger.debug("Saved Tweet")
        rescue ActiveRecord::RecordNotUnique
          $logger.info("Can't Save Tweet: Duplicate")
        end
      when "FAVORITE"
        $logger.debug("Received Favorite")
        begin
          Favorite.create!(:tweet_id => json[:tweet_id],
                           :user_id => json[:user_id])
          $logger.debug("Saved Favorite")
        rescue ActiveRecord::RecordNotUnique
          $logger.info("Can't Save Tweet: Duplicate")
        end
      when "UNFAVORITE"
        Favorite.delete_all("tweet_id = #{json[:tweet_id]} AND user_id = #{json[:user_id]}")
      when "RETWEET"
        $logger.debug("Received Retweet")
        begin
          Retweet.create!(:id => json[:id],
                          :tweet_id => json[:tweet_id],
                          :user_id => json[:user_id])
          $logger.debug("Saved Retweet")
        rescue ActiveRecord::RecordNotUnique
          $logger.info("Can't Save Retweet: Duplicate")
        end
      when "DELETE"
        tweet = Tweet.find_by(:id => json[:id]) || Retweet.find_by(:id => json[:id])
        if tweet
          tweet.destroy
        end
      else
        # ???
        puts "???????"
      end
    end
    @@wq.start

    def initialize
      @worker_number = nil
      @receive_buf = ""
    end

    def post_init
      # なにもしない。クライアントが
    end

    def unbind
      $connections.delete_if{|k, v| v == self}
      $logger.info("Connection closed")
    end

    def send_account_all
      Account.where("user_id % ? = ?", $worker_count, @worker_number).each do |account|
        puts "Sent #{account.id}/#{account.user_id}"
        send_account(account)
      end
    end

    def send_account(account)
      send_chunk("ACCOUNT #{Yajl::Encoder.encode(account.attributes)}")
    end

    def receive_data(data)
      @receive_buf << data
      while line = @receive_buf.slice!(/.+?\r\n/)
        line.chomp!
        next if line == ""
        p line
        arg = line.split(/ /, 2)
        case arg.first
        when "CONNECT"
          ff = arg.last.split(/&/)
          secret_token = ff[0]
          worker_number = ff[1].to_i
          worker_count = ff[2].to_i
          if secret_token == Settings.secret_key
            if $worker_count != worker_count && $connections.size > 0
              $logger.error("Error: Worker Count Difference: $worker_count=#{$worker_count}, worker_count=#{worker_count}")
              send_chunk("ERROR Invalid Worker Count")
              close_connection_after_writing
            else
              $worker_count = worker_count
              $connections[worker_number] = self
              @worker_number = worker_number
              $logger.info("Connected: #{worker_number}")
              send_chunk("OK Connected")
              send_account_all
            end
          else
            $logger.error("Error: Invalid Secret Key")
            send_chunk("ERROR Invalid Secret Token")
            close_connection_after_writing
          end
        when "QUIT"
          send_chunk("BYE")
          close_connection_after_writing
        else
          @@wq.push arg
        end
      end
    end
  end

  class RegisterServer < EM::Connection
    def initialize
      @receive_buf = ""
    end

    def post_init
      p "connected"
    end

    def receive_data(data)
      @receive_buf << data
      while line = @receive_buf.slice!(/.+?\r\n/)
        line.chomp!
        next if line == ""
        p line
        sp = line.split(/ /, 2)
        if sp.first == "REGISTER"
          if sp.last =~ /^[0-9]+$/
            account = Account.find_by(:id => sp.last.to_i)
            if account
              if con = $connections[account.id % $worker_count]
                con.send_account(account)
                send_chunk("OK Registered")
              else
                send_chunk("OK Worker not found")
              end
            else
              $logger.error("Unknown account: #{sp.last}")
              send_chunk("ERROR Unknown Account")
            end
          else
            $logger.error("Invalid User ID")
            send_chunk("ERROR Invalid User ID")
          end
        else
          $logger.error("Unknown Command: #{sp})")
          send_chunk("ERROR Unknown command")
        end
        close_connection_after_writing
        return
      end
    end
  end

  def initialize
    $logger = Receiver::Logger.new(:info)
    $connections = {}
  end

  def start
    $logger.info("Database Proxy Started")
    EM.run do
      stop = Proc.new do
        EM.stop
      end
      Signal.trap(:INT, &stop)
      Signal.trap(:TERM, &stop)

      EM.start_server("0.0.0.0", Settings.db_proxy_port, DBProxyServer)
      EM.start_unix_domain_server(Settings.register_server_path, RegisterServer)
    end
  end
end

