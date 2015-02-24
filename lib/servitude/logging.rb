module Servitude
  module Logging

    %w(
      debug
      error
      fatal
      info
      warn
    ).each do |level|

      define_method level do |*messages|
        messages.each do |message|
          host_namespace.logger.send level, message
        end
      end

    end

    def host_namespace
      raise NotImplementedError
    end

  end
end
