class User < ActiveRecord::Base
  def initialize(attrs = {})
    if attrs.is_a?(Fixnum) || attrs.is_a?(Bignum)
      u = attrs
      attrs = {:id => u}
    end
    attrs[:profile_image_url] ||= ActionController::Base.helpers.asset_path("missing_profile_image.png")
    attrs[:name] ||= "Missing: id=#{u}"
    super(attrs)
  end

  has_many :tweets, :dependent => :delete_all
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all
end
