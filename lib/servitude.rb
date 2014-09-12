require 'servitude/version'
require 'rainbow'

module Servitude

  autoload :Actor,                    'servitude/actor'
  autoload :Base,                     'servitude/base'
  autoload :Cli,                      'servitude/cli'
  autoload :ConfigHelper,             'servitude/config_helper'
  autoload :Configuration,            'servitude/configuration'
  autoload :Daemon,                   'servitude/daemon'
  autoload :EnvironmentConfiguration, 'servitude/environment_configuration'
  autoload :Logging,                  'servitude/logging'
  autoload :PrettyPrint,              'servitude/pretty_print'
  autoload :ServerLogging,            'servitude/server_logging'
  autoload :Server,                   'servitude/server'
  autoload :ServerThreaded,           'servitude/server_threaded'
  autoload :SupervisionError,         'servitude/supervision_error'

  INT  = "INT"
  TERM = "TERM"

  class << self
    attr_accessor :boot_called
  end

end
