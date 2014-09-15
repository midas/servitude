module Servitude
  module Cli
    class Service < Base

      def self.environment_option
        method_option :environment, desc: "The environment to execute in", type: :string, aliases: '-e'
      end

      def self.pid_option
        method_option :pid, desc: "The path for the PID file", type: :string, default: Servitude::NS::DEFAULT_PID_PATH
      end

      def self.common_start_options
        method_option :config, type: :string, aliases: '-c', desc: "The path for the config file", default: Servitude::NS::DEFAULT_CONFIG_PATH
        environment_option
        method_option :log_level, desc: "The log level", type: :string, aliases: '-o', default: 'info'
        method_option :log, desc: "The path for the log file", type: :string, aliases: '-l', default: Servitude::NS::DEFAULT_LOG_PATH
        method_option :threads, desc: "The number of threads", type: :numeric, aliases: '-t', default: Servitude::NS::DEFAULT_THREAD_COUNT
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
          server = Servitude::NS::Server.new( options.merge( use_config: Servitude::NS::USE_CONFIG, log: 'STDOUT' ))
          server.start
        end

        def start_daemon
          server = Servitude::Daemon.new( options.merge( use_config: Servitude::NS::USE_CONFIG ))
          server.start
        end

      end

      desc "status", "Check the status of the server daemon"
      pid_option
      def status
        Servitude::Daemon.new( options.merge( use_config: Servitude::NS::USE_CONFIG )).status
      end

      desc "stop", "Stop the server daemon"
      pid_option
      def stop
        server = Servitude::Daemon.new( options.merge( use_config: Servitude::NS::USE_CONFIG ))
        server.stop
      end

      def self.handle_no_command_error( name )
        puts "Unrecognized command: #{name}"
      end

    end
  end
end
