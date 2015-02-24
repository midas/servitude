# coding: utf-8

require 'servitude'

module Servitude
  module Base

    def self.included( base )
      base.extend( ClassMethods )
      base.class_eval do
        class << self
          attr_accessor :boot_called,
                        :configuration,
                        :logger
        end
      end
    end

    module ClassMethods

      def boot( app_id: ( host_namespace.name.split( '::' ).join( '-' ).downcase rescue nil ),
                app_name: ( host_namespace.name.split( '::' ).join( ' ' ) rescue nil ),
                author: nil,
                attribution: ( "v#{host_namespace::VERSION} Copyright © #{Time.now.year} #{author}" rescue nil ),
                use_config: false,
                default_config_path: nil,
                server_class: ( host_namespace::Server rescue "#{host_namespace.name}::Server" ))
        unless app_id
          raise ArgumentError, 'app_id keyword is required'
        end
        unless app_name
          raise ArgumentError, 'app_name keyword is required'
        end
        unless author
          raise ArgumentError, 'author keyword is required'
        end
        unless attribution
          raise ArgumentError, 'attribution keyword is required'
        end

        unless server_class
          raise ArgumentError, 'server_class keyword is required'
        end

        const_set :APP_ID, app_id
        const_set :APP_NAME, app_name
        const_set :AUTHOR, author
        const_set :ATTRIBUTION, attribution
        const_set :DEFAULT_CONFIG_PATH, default_config_path
        const_set :SERVER_CLASS, server_class
        const_set :USE_CONFIG, use_config

        host_namespace.boot_called = true
      end

      # Override to contradict convention of Server being nested
      # in ::host_namespace
      #
      def host_namespace
        self
      end

      def server_class
        case self::SERVER_CLASS
          when String, Symbol
            eval self::SERVER_CLASS.to_s, binding, __FILE__, __LINE__
          else
            self::SERVER_CLASS
        end
      end

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

      def configure
        yield( configuration ) if block_given?
      end

    end
  end
end
