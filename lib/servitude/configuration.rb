require 'hashie'
require 'pathname'
require 'servitude'
require 'yaml'

module Servitude
  class Configuration < Hashie::Mash

    def self.load( options={} )
      merged_options = defaults.merge( file_options )
      merged_options = merged_options.merge( options )
      new( merged_options )
    end

    def self.config_filepath
      Servitude::DEFAULT_CONFIG_PATH
    end

    def config_filepath
      Pathname.new( self.class.config_filepath )
    end

    def slice( *keys )
      klass.new( select { |k,v| keys.map( &:to_s ).include?( k ) } )
    end

    def for_env
      return Hashie::Mash.new({}) unless env
      self[env]
    end

  protected

    # Override to povide default config values
    #
    def self.defaults
      {
        threads: 1
      }
    end

    def self.file_options
      return {} unless config_filepath

      File.exists?( config_filepath ) ?
        load_file_options :
        {}
    end

    def self.load_file_options
      YAML::load( File.read( config_filepath ))
    end

    def klass
      self.class
    end

  end
end
