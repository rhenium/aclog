module ApplicationHelper
  include Twitter::Autolink

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
