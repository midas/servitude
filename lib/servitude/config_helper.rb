module Servitude
  module ConfigHelper

    def config
      host_namespace.configuration
    end

    def host_namespace
      raise NotImplementedError
    end

  end
end
