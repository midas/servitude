require 'servitude'

# Provides logging services for the base server.
#
module Servitude
  module ServerLogging

  protected

    def initialize_loggers
      host_namespace.initialize_loggers log_level: log_level
    end

    def log_startup
      start_banner.each do |line|
        host_namespace.logger.info line
      end
    end

    def start_banner
      [
        "",
        "***",
        "* #{host_namespace::APP_NAME} started",
        "*",
        "* #{host_namespace::ATTRIBUTION}",
        "*",
        ((host_namespace.configuration.nil? || host_namespace.configuration.empty?) ? nil : "* Configuration"),
        PrettyPrint::configuration_lines( host_namespace.configuration, "*  ", all_config_filters ),
        ((host_namespace.configuration.nil? || host_namespace.configuration.empty?) ? nil : "*"),
        "***",
      ].flatten.reject( &:nil? )
    end

    def log_level
      (host_namespace.configuration.log_level.to_sym rescue :info)
    end

    def all_config_filters
      default_config_filters + config_filters
    end

    def default_config_filters
      %w(
        help
        interactive
      )
    end

    # Override for custom config filtering
    #
    def config_filters
      []
    end

    def host_namespace
      raise NotImplementedError
    end

    #def config_value( key )
      #value = host_namespace.configuration.send( key )

      #return value unless value.is_a?( Hash )

      #return redacted_hash( value )
    #end

    #def redacted_hash( hash )
      #redacted_hash = {}

      #hash.keys.
           #collect( &:to_s ).
           #grep( /#{redacted_keys}/i ).
           #each do |blacklisted_key|
        #value = hash[blacklisted_key]
        #redacted_hash[blacklisted_key] = value.nil? ? nil : '[REDACTED]'
      #end

      #hash.merge( redacted_hash )
    #end

    #def redacted_keys
      #%w(
        #password
      #).join( '|' )
    #end

  end
end
