# coding: utf-8

require 'servitude'

module Servitude
  module Base

    def self.included( base )
      base.extend( ClassMethods )
      base.class_eval do
        class << self
          attr_accessor :logger
        end
      end
    end

    module ClassMethods

      def boot( host_namespace: raise(ArgumentError, 'host_namespace keyword is required'),
                app_id: host_namespace.name.split( '::' ).join( '-' ).downcase,
                app_name: host_namespace.name.split( '::' ).join( ' ' ),
                company: raise(ArgumentError, 'company keyword is required'),
                use_config: false,
                default_config_path: nil,
                default_log_path: nil,
                default_pid_path: nil,
                default_thread_count: nil,
                version_copyright: "v#{host_namespace::VERSION} Copyright © #{Time.now.year} #{company}" )
        Servitude::const_set :NS, host_namespace

        const_set :APP_ID, app_id
        const_set :APP_NAME, app_name
        const_set :COMPANY, company
        const_set :DEFAULT_CONFIG_PATH, default_config_path
        const_set :DEFAULT_LOG_PATH, default_log_path
        const_set :DEFAULT_PID_PATH, default_pid_path
        const_set :DEFAULT_THREAD_COUNT, default_thread_count
        const_set :USE_CONFIG, use_config
        const_set :VERSION_COPYRIGHT, version_copyright

        Servitude::boot_called = true
      end

      def configuration
        @configuration
      end

      def configuration=( configuration )
        @configuration = configuration
      end

      def configure
        yield( configuration ) if block_given?
      end

    end
  end
end
