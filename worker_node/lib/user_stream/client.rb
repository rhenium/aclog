require "em-http/middleware/oauth"

module UserStream
  class Client
    attr_reader :options

    def initialize(options)
      @options = options
      @callbacks = {}
      @exiting = false
    end

    def update(options)
      @options = options
      reconnect
    end

    def update_if_necessary(options)
      if options[:oauth][:access_token] == @options[:oauth][:access_token]
        update(options)
        true
      else
        false
      end
    end

    def reconnect
      close
      connect
    end

    def stop
      @exiting = true
      close
    end

    def close
      @http.close
    end

    def connect
      error = nil
      errorbuf = ""
      buftok = BufferedTokenizer.new("\r\n")
      json_parser = Yajl::Parser.new(symbolize_keys: true)
      @http = setup_connection

      json_parser.on_parse_complete = -> json {
        callback(:item, json)
      }

      @http.headers do |headers|
        case status = @http.response_header.status
        when 200
          # yay!
        when 401
          error = :unauthorized
        when 420
          error = :enhance_your_calm
        when 503
          error = :service_unavailable
        else
          error = "status_#{status}".to_sym
        end
      end

      @http.stream do |chunk|
        if error
          errorbuf << chunk
          next
        end

        buftok.extract(chunk).each do |line|
          json_parser << line
        end
      end

      @http.callback do
        if error
          if @callbacks.key?(error)
            callback(error, errorbuf)
          else
            callback(:error, "#{error}: #{errorbuf}")
          end
        else
          callback(:disconnected)
        end
      end

      @http.errback do
        callback(:error, @http.error) unless @exiting
      end
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

    def setup_connection
      opts = { query: {}, head: {} }
      opts[:query].merge!(@options[:params]) if @options[:params].is_a? Hash
      opts[:head]["accept-encoding"] = "gzip" if @options[:compression]

      req = EM::HttpRequest.new("https://userstream.twitter.com/1.1/user.json", inactivity_timeout: 100) # at least one line per 90 seconds will come
      req.use(EM::Middleware::OAuth, @options[:oauth])

      req.get(opts)
    end
  end
end
