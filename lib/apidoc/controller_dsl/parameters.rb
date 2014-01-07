module Apidoc
  module ControllerDsl
    module Parameters
      def requires(name, validation, description)
        _apidoc_current_endpoint.parameters << Parameter.new(name, validation, description, required: true)
      end

      def optional(name, validation, description)
        _apidoc_current_endpoint.parameters << Parameter.new(name, validation, description, required: false)
      end

      def param_group(name, &blk)
        if block_given?
          _apidoc_param_groups[name] = blk
        else
          blk = _apidoc_param_groups[name]
          if blk
            blk.call
          else
            raise DslError, "Parameters group #{name} is not defined."
          end
        end
      end
    end
  end
end

