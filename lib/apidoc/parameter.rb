module Apidoc
  class Parameter
    attr_reader :name, :validator, :description, :required
    alias required? required

    def initialize(name, validation, description, required: false)
      @name = name
      @validator = parse_validation(validation)
      @description = description
      @required = required
    end

    def parse_validation(validation)
      case validation
      when :integer
        ->(value) { /^[1-9][0-9]*$/ =~ value }
      when :string
        ->(value) { true }
      when Regexp
        ->(value) { validation =~ value }
      else
        if validation.is_a?(Range) && validation.begin.is_a?(Integer)
          ->(value) { /^[1-9][0-9]*$/ =~ value && validation === value.to_i }
        else
          raise DslError, "Not implemented validation type: #{validation}."
        end
      end
    end

    def validate!(params)
      if self.required && params[self.name].blank?
        raise ParameterMissing, self.name
      end

      if !params[self.name].nil? && !self.validator.call(params[self.name])
        raise ParameterInvalid, self.name
      end
    end
  end
end
