module Utils
  extend ActiveSupport::Concern

  def bot_request?
    bot_uas = [
      "spider",
      "yahoo",
      "libwww",
      "curl",
      "wget",
      "facebook",
      "tumblr",
      "google",
      "twitterbot",
    ]

    bot_uas.any? {|ua|
      request.user_agent.downcase.include?(ua)
    }
  end
end
