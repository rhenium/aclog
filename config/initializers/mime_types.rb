# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime.__send__(:remove_const, "HTML")
Mime::Type.register "application/xhtml+xml", :html
