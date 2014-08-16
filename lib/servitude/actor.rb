require 'celluloid/autostart'

module Servitude
  module Actor

    def self.included( base )
      base.class_eval do
        include Celluloid
      end
    end

  end
end
