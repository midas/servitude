require 'yell'

# Provides logging services for the base server.
#
module Servitude
  module ServerLogging

  protected

    def initialize_loggers
      Servitude::NS.logger = Yell.new do |l|
        l.level = log_level
        l.adapter $stdout, :level => [:debug, :info, :warn]
        l.adapter $stderr, :level => [:error, :fatal]
      end
    end

    def log_startup
      start_banner.each do |line|
        Servitude::NS.logger.info line
      end
    end

    def start_banner
      [
        "",
        "***",
        "* #{Servitude::NS::APP_NAME} started",
        "*",
        "* #{Servitude::NS::VERSION_COPYRIGHT}",
        "*",
        (Servitude::NS::configuration.empty? ? nil : "* Configuration"),
        PrettyPrint::configuration_lines( Servitude::NS::configuration, "*  ", all_config_filters ),
        (Servitude::NS::configuration.empty? ? nil : "*"),
        "***",
      ].flatten.reject( &:nil? )
    end

    def log_level
      ((Servitude::NS::configuration.log_level || :info).to_sym rescue :info)
    end

    def all_config_filters
      default_config_filters + config_filters
    end

    def default_config_filters
      %w(
        help
        interactive
        interactive_given
      )
    end

    # Override for custom config filtering
    #
    def config_filters
      []
    end

    #def config_value( key )
      #value = Servitude::NS.configuration.send( key )

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
