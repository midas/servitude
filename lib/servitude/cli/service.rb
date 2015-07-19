require 'servitude'

module Servitude
  module Cli
    class Service < Base

      def self.environment_option
        method_option :environment, desc: "The environment to execute in", type: :string, aliases: '-e'
      end

      def self.pid_option
        method_option :pid, desc: "The path for the PID file", type: :string
      end

      def self.common_start_options
        method_option :config, type: :string, aliases: '-c', desc: "The path for the config file"
        environment_option
        method_option :log_level, desc: "The log level", type: :string, aliases: '-o'
        method_option :log, desc: "The path for the log file", type: :string, aliases: '-l'
        method_option :threads, desc: "The number of threads", type: :numeric, aliases: '-t'
      end

      desc "restart", "Stop and start the server"
      common_start_options
      pid_option
      def restart
        stop
        start_daemon
      end

      desc "start", "Start the server"
      common_start_options
      pid_option
      method_option :interactive, type: :boolean, aliases: '-i', desc: "Start the server in interactive mode", default: false
      def start
        if options[:interactive]
          start_interactive
        else
          start_daemon
        end
      end

      no_commands do

        def start_interactive
          server = host_namespace::server_class.new( configuration( options, use_config: host_namespace::USE_CONFIG, log: 'STDOUT' ))
          server.start
        end

        def start_daemon
          server = Servitude::Daemon.new( host_namespace::APP_NAME,
                                          host_namespace::server_class,
                                          configuration( options, use_config: host_namespace::USE_CONFIG ))
          server.start
        end

        def configuration_class
          Servitude::Configuration
        end

        def configuration( options, additional_options={} )
          unless options[:config]
            options = options.merge( config: host_namespace::DEFAULT_CONFIG_PATH )
          end

          options = options.merge( additional_options )
          host_namespace.configuration = configuration_class.load( host_namespace::DEFAULT_CONFIG_PATH, options )
        end

        def host_namespace
          raise NotImplementedError
        end

      end

      desc "status", "Check the status of the server daemon"
      pid_option
      method_option :quiet, type: :boolean, aliases: '-q', desc: "Do not prompt to remove an old PID file", default: false
      def status
        result = Servitude::Daemon.new( host_namespace::APP_NAME,
                                        host_namespace::server_class,
                                        configuration( options, use_config: host_namespace::USE_CONFIG  )).status
        at_exit { exit result }
      end

      desc "stop", "Stop the server daemon"
      pid_option
      method_option :quiet, type: :boolean, aliases: '-q', desc: "Do not prompt to remove an old PID file", default: false
      def stop
        server = Servitude::Daemon.new( host_namespace::APP_NAME,
                                        host_namespace::server_class,
                                        configuration( options, use_config: host_namespace::USE_CONFIG ))
        server.stop
      end

      def self.handle_no_command_error( name )
        puts "Unrecognized command: #{name}"
      end

    end
  end
end
