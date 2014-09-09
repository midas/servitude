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

        attr_reader :options
      end
    end

    def initialize( options )
      unless Servitude.boot_called
        raise 'You must call boot before starting server'
      end

      @options = options

      run_hook :before_initialize
      initialize_loggers
      run_hook :after_initialize
    end

    def start
      log_startup
      run

      trap INT do
        Thread.new { finalize; exit }.join
      end

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

  end
end
