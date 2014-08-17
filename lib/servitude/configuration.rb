module Servitude
  module Configuration

    def self.included( base )
      base.extend ClassMethods

      base.class_eval do
        class << self
          attr_accessor :attributes,
                        :configured
        end
      end
    end

    module ClassMethods

      def configurations( *attrs )
        raise 'Already configured: cannot call configurations more than once' if self.configured

        self.attributes = attrs.map { |attr| Array( attr ).first.to_s }

        class_eval do
          attr_accessor( *self.attributes )
        end

        attrs.select { |attr| attr.is_a?( Array ) }.
              each do |k, v|

          define_method k do
            instance_variable_get( "@#{k}" ) ||
              instance_variable_set( "@#{k}", v )
          end

        end

        self.configured = true
      end

      def from_file( file_path )
        unless File.exists?( file_path )
          raise "Configuration file #{file_path} does not exist"
        end

        options = Oj.load( File.read( file_path ))
        Servitude::NS::configuration = Servitude::NS::Configuration.new

        attributes.each do |c|
          if options[c]
            Servitude::NS::configuration.send( :"#{c}=", options[c] )
          end
        end

        options[:config_loaded] = true
      end

    end
  end
end
