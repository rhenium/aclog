class SearchController < ApplicationController
  include Aclog::Twitter

  def search
    @caption = "search"
    @tweets = Tweet.where(parse_query(params[:query])).reacted.recent(7).order_by_id.list(params, force_page: true)
  end

  private
  def parse_query(input)
    str = input.dup
    strings = []
    str.gsub!(/"((?:\\"|[^"])*?)"/) {|m| strings << $1; "##{strings.size - 1}" }
    groups = []
    while str.sub!(/\(([^()]*?)\)/) {|m| groups << $1; "$#{groups.size - 1}" }; end

    conv = -> s do
      s.scan(/\S+(?: OR \S+)*/).map {|co|
        co.split(" OR ").map {|token|
          if /^\$(\d+)$/ =~ token
            conv.call(groups[$1.to_i])
          else
            parse_condition(token, strings)
          end
        }.inject(&:or)
      }.inject(&:and)
    end
    conv.call(str)
  end

  def parse_condition(token, strings)
    tweets = Tweet.arel_table
    escape_text = -> str do
      str.gsub(/#(\d+)/) { strings[$1.to_i] }
         .gsub("%", "\\%")
         .gsub("*", "%")
         .gsub("_", "\\_")
         .gsub("?", "_")
    end

    positive = token[0] != "-"
    case token
    when /^-?(?:user|from):([A-Za-z0-9_]{1,20})$/
      u = User.find_by(screen_name: $1)
      uid = u && u.id || 0
      tweets[:user_id].__send__(positive ? :eq :not_eq, uid)
    when /^-?date:(\d{4}(-?)\d{2}\2\d{2})(?:\.\.|-)(\d{4}\2\d{2}\2\d{2})$/ # $1: begin, $2: end
      tweets[:id].__send__(positive ? :in : :not_in, snowflake(Date.parse($1))...snowflake(Date.parse($3) + 1))
    when /^-?favs?:(\d+)$/
      tweets[:favorites_count].__send__(positive ? :gteq : :lt, $1.to_i)
    when /^-?rts?:(\d+)$/
      tweets[:retweets_count].__send__(positive ? :gteq : :lt, $1.to_i)
    when /^-?(?:sum|reactions?):(\d+)$/
      (tweets[:favorites_count] + tweets[:retweets_count]).__send__(positive ? :gteq : :lt, $1.to_i)
    when /^(?:source|via):(.+)$/
      source_text = "<url:%:#{escape_text.call($1).gsub(":", "%3A")}>"
      tweets[:source].__send__(positive ? :matches : :does_not_match, source_text)
    else
      search_text = escape_text.call(positive ? token : token[1..-1])
      tweets[:text].__send__(positive ? :matches : :does_not_match, "%#{search_text}%")
    end
  end
end
