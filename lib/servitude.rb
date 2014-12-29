require 'autoloaded'
require 'rainbow'
require 'yell'

module Servitude

  Autoloaded.module do |autoloaded|
    autoloaded.with :VERSION
  end

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

    def server_class
      case SERVER_CLASS
        when String, Symbol
          eval SERVER_CLASS.to_s, binding, __FILE__, __LINE__
        else
          SERVER_CLASS
      end
    end
  end

  Servitude.initialize_loggers log_level: :info

end
