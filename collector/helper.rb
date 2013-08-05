# -*- encoding: utf-8 -*-

module Aclog
  module Collector
    module Helper
      def format_text(status)
        text = status[:text]
        entities = status[:entities].map{|k, v| v.map{|n| n.update(type: k)}}.flatten.sort_by{|entity| entity[:indices].first}

        result = ""
        last_index = entities.inject(0) do |last_index_, entity|
          result << text[last_index_...entity[:indices].first]
          case entity[:type]
          when :urls, :media
            result << "<url:#{escape_colon(entity[:expanded_url])}:#{escape_colon(entity[:display_url])}>"
          when :hashtags
            result << "<hashtag:#{entity[:text]}>"
          when :user_mentions
            result << "<mention:#{entity[:screen_name]}>"
          when :symbols
            result << "<symbol:#{entity[:text]}>"
          end

          entity[:indices].last
        end
        result << text[last_index..-1]

        result
      end

      def format_source(status)
        if status[:source].include?("<a")
          url, name = status[:source].scan(/<a href="(.+?)" rel="nofollow">(.+?)<\/a>/).flatten
          "<url:#{escape_colon(url)}:#{escape_colon(name)}>"
        else
          # web, txt, ..
          status[:source]
        end
      end

      private
      # escape ":" to "\\:". "\\" is in neither Unreserved Characters nor Reserved Characters (RFC3986)
      def escape_colon(str); str.gsub(":", "\\:") end
    end
  end
end
