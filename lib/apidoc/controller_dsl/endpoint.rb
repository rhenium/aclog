module Apidoc
  module ControllerDsl
    module Endpoints
      def get(endpoint)
        _apidoc_endpoint(:get, endpoint)
      end

      def post(endpoint)
        _apidoc_endpoint(:post, endpoint)
      end

      def _apidoc_endpoint(method, endpoint)
        if _apidoc_endpoint_started?
          raise DslError, "Previous endpoint #{_apidoc_current_endpoint} definition is not completed."
        end

        self._apidoc_current_endpoint = Endpoint.new(method, endpoint)
      end

      def description(description)
        _apidoc_current_endpoint.description = description
      end

      def see(action_name)
        _apidoc_current_endpoint.sees << action_name.to_sym
      end
    end
  end
end

