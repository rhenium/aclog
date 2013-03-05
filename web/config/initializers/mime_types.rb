# Be sure to restart your server when you modify this file.
module Mime
  remove_const("HTML")
end
# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
Mime::Type.register "text/html", :html
Mime::Type.register "application/xhtml+xml", :xhtml

