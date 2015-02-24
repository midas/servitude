require 'hashie'
require 'pathname'
require 'yaml'

module Servitude
  class Configuration < Hashie::Mash

    def self.load( config_filepath, options={} )
      merged_options = defaults.merge( file_options( config_filepath ))
      merged_options = merged_options.merge( options )
      new( merged_options )
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

    def self.file_options( config_filepath )
      return {} unless config_filepath

      File.exists?( config_filepath ) ?
        load_file_options( config_filepath ) :
        {}
    end

    def self.load_file_options( config_filepath )
      YAML::load( File.read( config_filepath ))
    end

    def klass
      self.class
    end

  end
end
