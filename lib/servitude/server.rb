require 'servitude'
require 'hooks'

module Servitude
  module Server

    def self.included( base )
      base.class_eval do
        include Logging
        include ServerLogging
        include Hooks

        define_hook :after_initialize,
                    :before_initialize,
                    :before_sleep,
                    :finalize

        attr_reader :cli_options
      end
    end

    def initialize( cli_options={} )
      unless Servitude.boot_called
        raise 'You must call boot before starting server'
      end

      @cli_options = cli_options

      run_hook :before_initialize
      initialize_config
      initialize_loggers
      run_hook :after_initialize
    end

    def start
      log_startup

      trap( INT )  { stop }
      trap( TERM ) { stop }

      run
      run_hook :before_sleep
      sleep
    end

  protected

    def run
      raise NotImplementedError
    end

    def initialize_config
      Servitude::NS::configuration = configuration_class.new( cli_options )
    end

    def configuration_class
      Servitude::Configuration
    end

  private

    def finalize
      run_hook :finalize
    end

    def stop
      Thread.new { finalize; exit }.join
    end

  end
end
