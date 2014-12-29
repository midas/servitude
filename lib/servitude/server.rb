require 'hooks'
require 'servitude'

module Servitude
  module Server

    def self.included( base )
      base.class_eval do
        include ConfigHelper
        include Logging
        include ServerLogging
        include Hooks

        define_hook :after_initialize,
                    :before_initialize,
                    :before_run,
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
      initialize_loggers
      run_hook :after_initialize
    end

    def start
      log_startup

      trap( INT )  { stop }
      trap( TERM ) { stop }

      run_hook :before_run
      run
      run_hook :before_sleep
      sleep
    end

  protected

    def run
      raise NotImplementedError
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
