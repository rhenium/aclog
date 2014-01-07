module Apidoc
  module ControllerDsl
    include Resources
    include Endpoints
    include Parameters

    private
    def method_added(method_name)
      super(method_name)

      if _apidoc_endpoint_started?
        orig_method = self.instance_method(method_name)
        current_endpoint = _apidoc_current_endpoint
        _apidoc_resource.endpoints[method_name] = _apidoc_current_endpoint
        self._apidoc_current_endpoint = nil

        define_method(method_name) do |*args|
          current_endpoint.validate!(params)
          orig_method.bind(self).call(*args)
        end
      end
    end

    def _apidoc_resource
      name = self.name.sub(/Controller$/, "").underscore
      Apidoc.resources[name.to_sym] ||= Resource.new(name.titleize)
    end

    def _apidoc_current_endpoint
      @_apidoc_current_endpoint || raise(DslError, "Endpoint definition is not started.")
    end

    def _apidoc_current_endpoint=(value)
      @_apidoc_current_endpoint = value
    end

    def _apidoc_endpoint_started?
      @_apidoc_current_endpoint.present?
    end

    def _apidoc_param_groups
      @_apidoc_param_groups ||= {}
    end
  end
end
