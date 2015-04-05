module TweetsHelper
  def header
    orig = @header || @title
    orig
      .sub(/@\w{1,20}'s/) {|t| "<small>#{t.delete("@")}</small>" }
      .sub(/\w+ by @\w{1,20}/) {|t| "<small>#{t.delete("@")}</small>" }
      .html_safe
  end
end
