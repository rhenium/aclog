require "em-http/middleware/oauth"

module UserStream
  class Client
    attr_reader :options

    def initialize(options = {})
      @options = { compression: true }.merge(options).freeze
      @callbacks = {}
      @closing = false
    end

    def update(options = {})
      initialize(options)
      reconnect
    end

    def reconnect
      close
      connect
    end

    def close
      @closing = true
      @http.close
    end

    def connect
      @buftok = BufferedTokenizer.new("\r\n")

      opts = { query: (@options[:params] || {}),
               head: { "accept-encoding": @options[:compression] ? "gzip" : "" } }
      oauth = { consumer_key: @options[:consumer_key],
                consumer_secret: @options[:consumer_secret],
                access_token: @options[:oauth_token],
                access_token_secret: @options[:oauth_token_secret] }
      req = EM::HttpRequest.new("https://userstream.twitter.com/1.1/user.json")
      req.use(EM::Middleware::OAuth, oauth)
      http = req.get(opts)

      http.headers do |headers|
      end

      http.stream do |chunk|
        @buftok.extract(chunk).each do |line|
          next if line.empty?
          callback(:item, line)
        end
      end

      http.callback do
        case http.response_header.status
        when 401
          callback(:unauthorized, http.response)
        when 420
          callback(:enhance_your_calm, http.response)
        when 503
          callback(:service_unavailable, http.response)
        when 200
          callback(:disconnected)
        else
          callback(:error, "#{http.response}: #{http.response}")
        end
      end

      http.errback do
        callback(:error, http.error) unless @closing
      end

      @http = http
    end

    def method_missing(name, &block)
      if /^on_.+/ =~ name.to_s
        @callbacks[name.to_s.sub(/^on_/, "").to_sym] = block
      end
    end

    private
    def callback(name, *args)
      @callbacks.key?(name) && @callbacks[name].call(*args)
    end
  end
end
