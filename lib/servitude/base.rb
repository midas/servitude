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

      def boot( app_id: ( self.name.split( '::' ).join( '-' ).downcase rescue nil ),
                app_name: ( self.name.split( '::' ).join( ' ' ) rescue nil ),
                author: nil,
                attribution: ( "v#{self::VERSION} Copyright © #{Time.now.year} #{author || company}" rescue nil ),
                use_config: false,
                default_config_path: nil,
                server_class: ( self::Server rescue "#{self.name}::Server" ))
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


        # TODO: Remove when host namespace deprecation expires
        const_set :APP_ID, app_id
        const_set :APP_NAME, app_name
        const_set :AUTHOR, author
        const_set :ATTRIBUTION, attribution
        const_set :DEFAULT_CONFIG_PATH, default_config_path
        const_set :USE_CONFIG, use_config

        Servitude.const_set :APP_ID, app_id
        Servitude.const_set :APP_NAME, app_name
        Servitude.const_set :AUTHOR, author
        Servitude.const_set :ATTRIBUTION, attribution
        Servitude.const_set :DEFAULT_CONFIG_PATH, default_config_path
        Servitude.const_set :SERVER_CLASS, server_class
        Servitude.const_set :USE_CONFIG, use_config

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
