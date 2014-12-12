require 'celluloid'

module Servitude
  module ServerThreaded

    def self.included( base )
      base.class_eval do
        after_initialize :initialize_thread
        after_initialize :initialize_celluloid_logger
      end
    end

  protected

    def handler_class
      raise NotImplementedError
    end

    def run
      raise NotImplementedError
    end

    def with_supervision( options={}, &block )
      begin
        block.call
      rescue Servitude::SupervisionError
        # supervisor is restarting actor
        warn_for_supevision_error
        notify_and_sleep_if_configured
        retry
      rescue Celluloid::DeadActorError
        # supervisor has yet to begin restarting actor
        warn_for_dead_actor_error
        notify_and_sleep_if_configured
        retry
      rescue => e
        handle_error( options, e )
      end
    end

    def notify_and_sleep_if_configured
      if config.supervision_retry_timeout_in_seconds &&
          config.supervision_retry_timeout_in_seconds > 0
        debug "Sleeping for #{config.supervision_retry_timeout_in_seconds}s ..."
        sleep( config.supervision_retry_timeout_in_seconds )
      end
    end

    def warn_for_supevision_error
      warn "RETRYING due to waiting on supervisor to restart actor ..."
    end

    def warn_for_dead_actor_error
      warn "RETRYING due to Celluloid::DeadActorError ..."
    end

    def handle_error( options, e )
      parts = [[e.class.name, e.message].join( ' ' ), format_backtrace( e.backtrace )]
      error( parts.join( "\n" ))
    end

    def format_backtrace( backtrace )
      "  #{backtrace.join "\n  "}"
    end

    # Correctly calls a single supervised actor when the threads configuraiton is set
    # to 1, or a pool of actors if threads configuration is > 1.  Also protects against
    # a supervised actor from being nil if the supervisor is reinitializing when access
    # is attempted.
    #
    def call_handler_respecting_thread_count( options )
      if config.threads > 1
        pool.async.call( options )
      else
        raise Servitude::SupervisionError unless handler
        handler.call( options )
      end
    end

    def pool
      @pool ||= handler_class.pool( size: config.threads )
    end

    def handler
      Celluloid::Actor[:handler]
    end

    def initialize_celluloid_logger
      Celluloid.logger = nil
    end

    def initialize_thread
      return unless config.threads == 1
      handler_class.supervise_as :handler
    end

  end
end
