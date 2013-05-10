# -*- encoding: utf-8 -*-

module Aclog
  module Collector
    module Helper
      def format_text(status)
        text = status[:text]
        entities = status[:entities].map{|k, v| v.map{|n| n.update(type: k)}}.flatten.sort_by{|entity| entity[:indices].first}

        result = ""
        last_index = entities.inject(0) do |last_index, entity|
          result << text[last_index...entity[:indices].first]
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
      def escape_colon(str); str.gsub(":", "%3A").gsub("<", "%3C").gsub(">", "%3E") end
    end
  end
end
