module Apidoc
  class Endpoint
    attr_reader :method, :name, :parameters
    attr_accessor :description

    def initialize(method, name)
      @method = method
      @name = name
      @parameters = []
      @description = nil
    end

    def to_s
      "#{method.to_s.upcase} #{name}"
    end

    def validate!(params)
      parameters.each do |parameter|
        parameter.validate!(params)
      end
    end
  end
end
