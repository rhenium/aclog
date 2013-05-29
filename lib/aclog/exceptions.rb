module Aclog
  module Exceptions
    class UserNotFound < StandardError; end
    class UserNotRegistered < StandardError; end
    class UserProtected < StandardError; end
    class LoginRequired < StandardError; end
    class TweetNotFound < StandardError; end
    class AccountPrivate < StandardError; end
    class OAuthEchoUnauthorized < StandardError; end
  end
end
