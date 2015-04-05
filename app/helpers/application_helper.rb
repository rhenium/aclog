module ApplicationHelper
  include Twitter::Autolink

  def register_view_part(name)
    (@view_parts ||= []) << name
  end

  def meta_info
    {
      controller: controller.controller_path,
      action: controller.action_name,
      parts: @view_parts.try(:join, " "),
      user_id: @user.try(:id),
      user_screen_name: @user.try(:screen_name),
      tweet_id: @tweet.try(:id)
    }
  end

  def title(name = nil, suffix = false)
    if name
      @title = name
      title
    else
      ["aclog", @title].compact.join(" - ")
    end
  end

  def link_to_with_active(name, options = {}, html_options = {}, &block)
    if current_page?(options)
      html_options[:class] = (html_options[:class].to_s + " active").strip
    end

    link_to name, options, html_options, &block
  end

  def profile_image_tag(user, size = :normal, options = {})
    capture_haml do
      haml_tag("img.twitter-icon",
               { src: user.profile_image_url(size),
                 alt: "@" + user.screen_name
               }.merge(options))
    end
  end

  def render_sidebars
    str = ""
    if @sidebars
      @sidebars.each do |sidebar|
        case sidebar
        when :user
          str << render("shared/sidebar/user")
        when :all
          str << render("shared/sidebar/all")
        when :reactions_thresholds
          str << render("shared/sidebar/reactions_thresholds")
        when :recent_thresholds
          str << render("shared/sidebar/recent_thresholds")
        end
      end
    end
    str.html_safe
  end

  def sidebar?
    @sidebars && @sidebars.size > 0
  end

  # utf8, form
  def utf8_enforcer_tag; raw "" end
end
