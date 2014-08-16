module Servitude
  module ServerThreaded

    def self.included( base )
      base.class_eval do
        after_initialize :initialize_thread
      end
    end

  protected

    def with_supervision( &block )
      begin
        block.call
      rescue Servitude::SupervisionError
        # supervisor is restarting actor
        #warn ANSI.cyan { "RETRYING due to waiting on supervisor to restart actor ..." }
        retry
      rescue Celluloid::DeadActorError
        # supervisor has yet to begin restarting actor
        #warn ANSI.blue { "RETRYING due to Celluloid::DeadActorError ..." }
        retry
      end
    end

    # Correctly calls a single supervised actor when the threads configuraiton is set
    # to 1, or a pool of actors if threads configuration is > 1.  Also protects against
    # a supervised actor from being nil if the supervisor is reinitializing when access
    # is attempted.
    #
    def call_handler_respecting_thread_count( options )
      if options[:threads] > 1
        pool.async.call( options )
      else
        raise Servitude::SupervisionError unless handler
        handler.call( options )
      end
    end

    def handler_class
      raise NotImplementedError
    end

    def run
      raise NotImplementedError
    end

    def pool
      @pool ||= handler_class.pool( size: options[:threads] )
    end

    def handler
      Celluloid::Actor[:handler]
    end

    def initialize_thread
      return unless options[:threads] == 1
      handler_class.supervise_as :handler
    end

  end
end
