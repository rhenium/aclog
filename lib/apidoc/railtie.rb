module Apidoc
  class Railtie < Rails::Railtie
    initializer "apidoc.controller_injections" do
      ActiveSupport.on_load :action_controller do
        extend ControllerDsl
      end
    end
  end
end
