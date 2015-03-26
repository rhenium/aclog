module ApplicationHelper
  include Twitter::Autolink

  def title(*args)
    content_for :title do
      (args.compact).join(" - ")
    end
  end

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

  # utf8, form
  def utf8_enforcer_tag; raw "" end
end
