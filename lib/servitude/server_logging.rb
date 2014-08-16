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

      #Celluloid.logger = Yell.new do |l|
        #l.level = :info
        #l.adapter :file, File.join( File.dirname( options[:log] ), "#{APP_ID}-celluloid.log" )
      #end
    end

    def log_startup
      start_banner( options ).each do |line|
        Servitude::NS.logger.info line
      end
    end

    def start_banner( options )
      [
        "",
        "***",
        "* #{Servitude::NS::APP_NAME} started",
        "*",
        "* #{Servitude::NS::VERSION_COPYRIGHT}",
        "*",
        "* Configuration:",
        (options[:config_loaded] ? "*   file: #{options[:config]}" : nil),
        Servitude::NS::Configuration.attributes.map { |a| "*   #{a}: #{config_value( a )}" },
        "*",
        "***",
      ].flatten.reject( &:nil? )
    end

    def log_level
      options.fetch( :log_level, :info ).to_sym
    end


    def config_value( key )
      value = Servitude::NS.configuration.send( key )

      return value unless value.is_a?( Hash )

      return redacted_hash( value )
    end

    def redacted_hash( hash )
      redacted_hash = {}

      hash.keys.
           collect( &:to_s ).
           grep( /#{redacted_keys}/i ).
           each do |blacklisted_key|
        value = hash[blacklisted_key]
        redacted_hash[blacklisted_key] = value.nil? ? nil : '[REDACTED]'
      end

      hash.merge( redacted_hash )
    end

    def redacted_keys
      %w(
        password
      ).join( '|' )
    end

  end
end
