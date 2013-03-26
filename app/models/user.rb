class User < ActiveRecord::Base
  def initialize(attrs = {})
    if attrs.is_a?(Fixnum) || attrs.is_a?(Bignum)
      u = attrs
      attrs = {:id => u}
    end
    attrs[:profile_image_url] ||= ActionController::Base.helpers.asset_path("missing_profile_image.png")
    attrs[:name] ||= "Missing name: #{u}"
    super(attrs)
  end

  has_many :tweets, :dependent => :delete_all
  has_many :favorites, :dependent => :delete_all
  has_many :retweets, :dependent => :delete_all

  def self.cached(uid)
    Rails.cache.fetch("user/#{uid}", :expires_in => 1.hour) do
      where(:id => uid).first
    end
  end

  def registered?
    Account.exists?(:user_id => id)
  end

  def profile_image_url_original
    profile_image_url.sub(/_normal((\.(png|jpeg|gif))?)/, "\\1")
  end
end
