require 'servitude'

module Servitude
  class EnvironmentConfiguration < Servitude::Configuration

    def for_env
      send( environment )
    end

  end
end
