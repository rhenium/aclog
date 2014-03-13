module AssignDefaultContentTypeAndCharsetXHTML
  private
  def assign_default_content_type_and_charset!(headers)
    @content_type = Mime::XHTML
    super(headers)
  end
end
ActionDispatch::Response.__send__(:include, AssignDefaultContentTypeAndCharsetXHTML)
