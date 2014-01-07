module Apidoc
  class Resource
    attr_reader :endpoints, :name
    attr_accessor :description

    def initialize(name)
      @name = name
      @description = nil
      @endpoints = {}
    end
  end
end
