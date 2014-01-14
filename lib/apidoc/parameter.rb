module Apidoc
  class Parameter
    attr_reader :name, :example, :description, :required
    alias required? required

    def initialize(name, example, description, required: false)
      @name = name
      @example = example
      @description = description
      @required = required
    end
  end
end
