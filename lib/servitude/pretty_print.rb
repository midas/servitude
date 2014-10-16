module Servitude
  module PrettyPrint

    def self.configuration_lines( config, pre='', filters=[] )
      return [] if config.nil? || config.empty?

      formatted = format_configuration( config )

      formatted.map do |line_parts|
        if !filters.nil? && !filters.empty? && filters.include?( line_parts.first )
          nil
        else
          [pre, line_parts.join( ': ' )].join
        end
      end.reject( &:nil? )
    end

    def self.format_configuration( config, path=[], result=[] )
      config.each do |element|
        key, value = *element
        cur_path = path + [key]
        if value.is_a?( Hash )
          format_configuration( value, cur_path, result )
        elsif value.is_a?( Array )
          result << [cur_path.map( &:to_s ).join( '.' ), value.inspect]
        else
          result << [cur_path.map( &:to_s ).join( '.' ), value]
        end
      end

      result
    end

  end
end
