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

  # utf8, form
  def utf8_enforcer_tag; raw "" end
end
