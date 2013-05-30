module Aclog
  module Exceptions
    class UserError < StandardError
      attr_reader :user
      def initialize(user)
        @user = user
      end
    end

    class UserNotFound < StandardError; end
    class LoginRequired < StandardError; end
    class TweetNotFound < StandardError; end
    class OAuthEchoUnauthorized < StandardError; end

    class UserNotRegistered < UserError; end
    class UserProtected < UserError; end
    class AccountPrivate < UserError; end
  end
end
