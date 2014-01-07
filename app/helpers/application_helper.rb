module ApplicationHelper
  def format_time(dt)
    dt.to_time.localtime("+09:00").strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_tweet_text(text)
    ret = text.gsub(/<([a-z]+?)(?<!\\):(.+?)(?:(?<!\\):(.+?))?>/) do
      case $1
      when "mention"
        screen_name = CGI.unescape($2)
        link_to("@#{screen_name}", "/#{screen_name}")
      when "url"
        n = [$3, $2.gsub(/(https?)%3A/, "\\1:")].map {|m| m.gsub("\\:", ":") }
        link_to(*n)
      when "hashtag"
        hashtag = CGI.unescape($2)
        link_to("##{hashtag}", "https://twitter.com/search?q=#{CGI.escape("##{hashtag}")}")
      when "symbol"
        symbol = CGI.unescape($2)
        link_to("$#{symbol}", "https://twitter.com/search?q=#{CGI.escape("$#{symbol}")}")
      else
        $&
      end
    end
    return ret
  end
  alias format_source_text format_tweet_text

  def title(*args)
    content_for :title do
      (args.compact).join(" - ")
    end
  end

  def caption(text)
    content_for :caption do
      if text.is_a? Symbol
        content_for(text)
      else
        text
      end
    end
  end

  def sidebar(name)
    content_for :sidebar do
      render "shared/sidebar/#{name}"
    end
  end

  # utf8, form
  def utf8_enforcer_tag; raw "" end
end
