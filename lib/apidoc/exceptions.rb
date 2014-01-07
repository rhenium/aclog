module Apidoc
  class Error < StandardError; end

  class ParameterMissing < Error
    def initialize(param)
      super("Parameter is missing or the value is empty: #{param}")
    end
  end

  class ParameterInvalid < Error
    def initialize(param)
      super("Parameter is invalid: #{param}")
    end
  end

  class DslError < SyntaxError; end
end
