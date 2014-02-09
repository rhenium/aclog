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

    class DocumentNotFound < StandardError; end

    class AclogError < StandardError; end
    class NotFound < AclogError; end
    class Forbidden < AclogError; end
    class OAuthEchoError < AclogError; end
  end
end
