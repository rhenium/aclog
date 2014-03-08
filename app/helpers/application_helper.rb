module ApplicationHelper
  include Twitter::Autolink

  def title(*args)
    content_for :title do
      (args.compact).join(" - ")
    end
  end

  def link_to_with_active(name, options = {}, html_options = {}, &block)
    if current_page?(options)
      html_options[:class] = (html_options[:class].to_s + " active").strip
    end

    link_to name, options, html_options, &block
  end

  def profile_image_tag(user, size = nil, options = {})
    if size
      url = user.__send__(:"profile_image_url_#{size}")
    else
      url = user.profile_image_url
    end

    capture_haml do
      haml_tag("img.twitter-icon",
               { src: url,
                 alt: "@" + user.screen_name,
                 onerror: "this.src = '#{image_path("profile_image_missing.png")}'"
               }.merge(options))
    end
  end

  # utf8, form
  def utf8_enforcer_tag; raw "" end
end
