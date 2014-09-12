require 'delegate'
require 'hashie'
require 'oj'

module Servitude
  class EnvironmentConfiguration < Servitude::Configuration

    def for_env
      _config.send( _config.environment )
    end

  end
end
