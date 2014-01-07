module Apidoc
  module ControllerDsl
    module Resources
      private
      def resource_description(description)
        _apidoc_resource.description = description
      end
    end
  end
end


