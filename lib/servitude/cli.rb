require 'rubygems'
require 'servitude'
require 'trollop'
require 'yell'

module Servitude
  module Cli

    def self.included( base )
      base.class_eval do
        attr_reader :cmd,
                    :options
      end
    end

    SUB_COMMANDS = %w(
      restart
      start
      status
      stop
    )

    def initialize( args )
      unless Servitude.boot_called
        raise 'You must call boot before starting server'
      end

      Trollop::options do
        version Servitude::NS::VERSION_COPYRIGHT
        banner <<-EOS
#{Servitude::NS::APP_NAME} #{Servitude::NS::VERSION_COPYRIGHT}

Usage:
  #{Servitude::NS::APP_ID} [command] [options]

  commands:
#{SUB_COMMANDS.map { |sub_cmd| "    #{sub_cmd}" }.join( "\n" )}

  (For help with a command: #{Servitude::NS::APP_ID} [command] -h)

options:
      EOS
        stop_on SUB_COMMANDS
      end

      # Get the sub-command and its options
      #
      @cmd = ARGV.shift || ''
      @options = case( cmd )
        when ''
          Trollop::die 'No command provided'
        when "restart"
          Trollop::options do
            opt :config, "The path for the config file", :type => String, :short => '-c', :default => Servitude::NS::DEFAULT_CONFIG_PATH
            opt :log_level, "The log level", :type => String, :default => 'info', :short => '-o'
            opt :log, "The path for the log file", :type => String, :short => '-l', :default => Servitude::NS::DEFAULT_LOG_PATH
            opt :pid, "The path for the PID file", :type => String, :default => Servitude::NS::DEFAULT_PID_PATH
            opt :threads, "The number of threads", :type => Integer, :default => Servitude::NS::DEFAULT_THREAD_COUNT, :short => '-t'
          end
        when "start"
          Trollop::options do
            opt :config, "The path for the config file", :type => String, :short => '-c', :default => Servitude::NS::DEFAULT_CONFIG_PATH
            opt :interactive, "Execute the server in interactive mode", :short => '-i'
            opt :log_level, "The log level", :type => String, :default => 'info', :short => '-o'
            opt :log, "The path for the log file", :type => String, :short => '-l', :default => Servitude::NS::DEFAULT_LOG_PATH
            opt :pid, "The path for the PID file", :type => String, :default => Servitude::NS::DEFAULT_PID_PATH
            opt :threads, "The number of threads", :type => Integer, :default => Servitude::NS::DEFAULT_THREAD_COUNT, :short => '-t'
          end
        when "status"
          Trollop::options do
            opt :pid, "The path for the PID file", :type => String, :default => Servitude::NS::DEFAULT_PID_PATH
          end
        when "stop"
          Trollop::options do
            opt :pid, "The path for the PID file", :type => String, :default => Servitude::NS::DEFAULT_PID_PATH
          end
        else
          Trollop::die "unknown command #{cmd.inspect}"
        end

      if cmd == 'start'
        unless options[:interactive]
          Trollop::die( :config, "is required when running as daemon" ) unless options[:config]
          Trollop::die( :log, "is required when running as daemon" ) unless options[:log]
          Trollop::die( :pid, "is required when running as daemon" ) unless options[:pid]
        end
      end

      if %w(restart status stop).include?( cmd )
        Trollop::die( :pid, "is required" ) unless options[:pid]
      end
    end

    def run
      send( cmd )
    end

  protected

    def start
      if options[:interactive]
        start_interactive
      else
        start_daemon
      end
    end

    def start_interactive
      server = Servitude::NS::Server.new( options.merge( log: nil ))
      server.start
    end

    def start_daemon
      server = Servitude::Daemon.new( options )
      server.start
    end

    def stop
      server = Servitude::Daemon.new( options )
      server.stop
    end

    def restart
      stop
      start_daemon
    end

    def status
      Servitude::Daemon.new( options ).status
    end

  end
end
