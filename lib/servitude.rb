require 'servitude/version'
require 'rainbow'
require 'yell'

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
  autoload :Util,                     'servitude/util'

  INT  = "INT"
  TERM = "TERM"

  class << self
    attr_accessor :boot_called, :configuration, :logger

    def initialize_loggers( log_level: nil, filename: nil )
      raise ArgumentError, 'log_level keyword is required' unless log_level

      logger.adapter.close if logger && logger.adapter

      self.logger = Yell.new do |l|
        l.level = log_level
        if filename
          l.adapter :file, filename, :level => [:debug, :info, :warn]
        else
          l.adapter $stdout, :level => [:debug, :info, :warn]
          l.adapter $stderr, :level => [:error, :fatal]
        end
      end
    end
  end

  Servitude.initialize_loggers log_level: :info

end
