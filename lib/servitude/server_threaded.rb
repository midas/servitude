module Servitude
  module ServerThreaded

    def self.included( base )
      base.class_eval do
        after_initialize :initialize_thread
      end
    end

  protected

    def handler_class
      raise NotImplementedError
    end

    def run
      raise NotImplementedError
    end

    def with_supervision( &block )
      begin
        block.call
      rescue Servitude::SupervisionError
        # supervisor is restarting actor
        warn_for_supevision_error
        sleep( config.supervision_retry_timeout || 0 )
        retry
      rescue Celluloid::DeadActorError
        # supervisor has yet to begin restarting actor
        warn_for_dead_actor_error
        sleep( config.supervision_retry_timeout || 0 )
        retry
      rescue => e
        handle_error( payload, delivery_info, e )
      end
    end

    def warn_for_supevision_error
      warn "RETRYING due to waiting on supervisor to restart actor ..."
    end

    def warn_for_dead_actor_error
      warn "RETRYING due to Celluloid::DeadActorError ..."
    end

    def handle_error( payload, delivery_info, e )
      error( "#{e.class.name} | #{e.message} | #{e.backtrace.inspect}" )
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

    def initialize_thread
      return unless config.threads == 1
      handler_class.supervise_as :handler
    end

  end
end
