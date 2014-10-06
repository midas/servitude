require 'delegate'
require 'hashie'
require 'oj'

module Servitude
  class Configuration < SimpleDelegator

    def initialize( options={} )
      options.reject! { |k,v| v.nil? }

      if options[:use_config]
        @_config = Hashie::Mash.new( file_options( options[:config] ))
        _config.merge!( options )
      else
        @_config = Hashie::Mash.new( options )
      end

      super _config
    end

  protected

    attr_reader :_config

    def file_options( file_path )
      unless File.file?( file_path )
        raise "Configuration file #{file_path} does not exist"
      end

      Oj.load( File.read( file_path ))
    end

  end
end
