module ApplicationHelper
  include Twitter::Autolink

  def register_view_part(name)
    (@view_parts ||= []) << name
  end

  def meta_info
    {
      controller: params[:controller],
      action: params[:action],
      parts: @view_parts.try(:join, " "),
      user_id: @user.try(:id),
      user_screen_name: @user.try(:screen_name),
      tweet_id: @tweet.try(:id),
      request_params: JSON.generate(params.to_hash.reject {|key, _| ["action", "controller", "oauth_token", "password"].include?(key) }),
    }
  end

  def title(name = nil, suffix = false)
    if name
      @title = name
      title
    else
      [@title, "aclog"].compact.join(" - ")
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

  def render_sidebar_content
    if user = @sidebars.delete(:user)
      parts = [:nav_user] + @sidebars
    elsif all = @sidebars.delete(:all)
      parts = [:nav_all] + @sidebars
    elsif apidocs = @sidebars.delete(:apidocs)
      parts = @sidebars
    end

    capture_haml do
      if user
        haml_concat render("shared/sidebar/user")
      elsif all
        haml_concat render("shared/sidebar/all")
      elsif apidocs
        haml_concat render("shared/sidebar/apidocs")
      end

      haml_tag(".sidebar-flex") do
        (parts || []).each do |part|
          haml_concat render("shared/sidebar/parts/#{part}")
        end
      end
    end
  end

  def sidebar?
    @sidebars && @sidebars.size > 0
  end

  # utf8, form
  def utf8_enforcer_tag; raw "" end
end
