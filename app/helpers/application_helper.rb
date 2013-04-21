module ApplicationHelper
  def format_time(dt)
    dt.to_time.localtime("+09:00").strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_tweet_text(text)
    ret = text.gsub(/<([a-z]+?):(.+?)(?::(.+?))?>/) do
      case $1
      when "mention"
        screen_name = CGI.unescape($2)
        link_to("@#{screen_name}", "/#{screen_name}")
      when "url"
        display = CGI.unescape($3)
        expanded_url = CGI.unescape($2)
        link_to(display, expanded_url)
      when "hashtag"
        hashtag = CGI.unescape($2)
        link_to("##{hashtag}", "https://twitter.com/search?q=#{CGI.escape("##{hashtag}")}")
      when "symbol"
        symbol = CGI.unescape($2)
        link_to("##{symbol}", "https://twitter.com/search?q=#{CGI.escape("$#{symbol}")}")
      else
        $&
      end
    end
    ret.gsub!(/\r\n|\r|\n/, "<br />")

    return ret
  end
  alias format_source_text format_tweet_text

  def twitter_status_url(tweet)
    "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
  end

  def twitter_user_url(screen_name)
    "https://twitter.com/#{screen_name}"
  end

  def user_icon_link(user)
    logger.error("DEPRECATED user_icon_link")
    link_to(image_tag(user.profile_image_url, alt: user.screen_name, title: user.name), user_path(user.screen_name))
  end

  def include_user?; get_bool(params[:include_user]) end
  def user_limit
    i = params[:limit].to_i
    if i > 0
      return i
    elsif i == -1
      return nil
    else
      if params[:action] == "show"
        return 100
      else
        return 20
      end
    end
  end

  # utf8, form
  def utf8_enforcer_tag
    raw ""
  end
end
