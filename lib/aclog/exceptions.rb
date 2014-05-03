module Aclog
  module Exceptions
    class AclogError < StandardError; end
    class NotFound < AclogError; end
    class Forbidden < AclogError; end
    class Unauthorized < AclogError; end

    class UserNotFound < NotFound; end
    class TweetNotFound < NotFound; end
    class UserNotRegistered < NotFound; end
    class DocumentNotFound < NotFound; end

    class UserProtected < Forbidden; end
    class AccountPrivate < Forbidden; end

    class OAuthEchoError < Unauthorized; end

    class OAuthEchoUnauthorized < OAuthEchoError; end

    class WorkerConnectionError < AclogError; end
  end
end
