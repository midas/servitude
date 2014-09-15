require 'rainbow'

module Servitude

  module Util

    def self.deprecate( deprecated_usage, sanctioned_usage )
      $stderr.print Rainbow( " *** DEPRECATED " ).yellow.inverse
      $stderr.print ' '
      $stderr.print Rainbow( deprecated_usage ).underline
      $stderr.print Rainbow(" -- use ")
      $stderr.print Rainbow( sanctioned_usage ).underline
      $stderr.print Rainbow(" instead")
      $stderr.puts ''
    end

  end

end
