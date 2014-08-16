require 'rubygems'
require 'fileutils'
require 'timeout'

module Servitude
  class Daemon

    attr_reader :name,
                :options,
                :pid,
                :pid_path,
                :script,
                :timeout

    def initialize( options )
      @options  = options
      @name     = options[:name] || Servitude::NS::APP_NAME
      @pid_path = options[:pid] || '.'
      @pid      = get_pid
      @timeout  = options[:timeout] || 10
    end

    def start
      abort "Process already running!" if process_exists?

      pid = fork do
        exit if fork
        Process.setsid
        exit if fork
        store_pid( Process.pid )
        File.umask 0000
        redirect_output!
        run
      end

      Process.waitpid( pid )
    end

    def run
      Servitude::NS::Server.new( options ).start
    end

    def stop
      case kill_process
        when :success
          remove_pid
        when :failed_to_stop
        when :does_not_exist
          puts "#{Servitude::NS::APP_NAME} process is not running"
          prompt_and_remove_pid_file if pid_file_exists?
        else
          raise 'Unknown return code from #kill_process'
      end
    end

    def status
      if process_exists?
        puts "#{Servitude::NS::APP_NAME} process running with PID: #{pid}"
      else
        puts "#{Servitude::NS::APP_NAME} process does not exist"
        prompt_and_remove_pid_file if pid_file_exists?
      end
    end

  protected

    def prompt_and_remove_pid_file
      puts "PID file still exists at '#{pid_path}', would you like to remove it (y/n)?"
      answer = $stdin.gets.strip
      if answer == 'y'
        remove_pid
        puts "Removed PID file"
      end
    end

    def remove_pid
      FileUtils.rm( pid_path ) if File.exists?( pid_path )
    end

    def store_pid( pid )
      File.open( pid_path, 'w' ) do |f|
        f.puts pid
      end
    rescue => e
      $stderr.puts "Unable to open #{pid_path} for writing:\n\t(#{e.class}) #{e.message}"
      exit!
    end

    def get_pid
      return nil unless File.exists?( pid_path )

      pid = nil

      File.open( @pid_path, 'r' ) do |f|
        pid = f.readline.to_s.gsub( /[^0-9]/, '' )
      end

      pid.to_i
    rescue Errno::ENOENT
      nil
    end

    def remove_pidfile
      File.unlink( pid_path )
    rescue => e
      $stderr.puts "Unable to unlink #{pid_path}:\n\t(#{e.class}) #{e.message}"
      exit
    end

    def kill_process
      return :does_not_exist unless process_exists?

      $stdout.write "Attempting to stop #{Servitude::NS::APP_NAME} process #{pid}..."
      Process.kill INT, pid

      iteration_num = 0
      while process_exists? && iteration_num < 10
        sleep 1
        $stdout.write "."
        iteration_num += 1
      end

      if process_exists?
        $stderr.puts "\nFailed to stop #{Servitude::NS::APP_NAME} process #{pid}"
        return :failed_to_stop
      else
        $stdout.puts "\nSuccessfuly stopped #{Servitude::NS::APP_NAME} process #{pid}"
      end

      return :success
    rescue Errno::EPERM
      $stderr.puts "No permission to query #{pid}!";
    end

    def pid_file_exists?
      File.exists?( pid_path )
    end

    def process_exists?
      return false unless pid
      Process.kill( 0, pid )
      true
    rescue Errno::ESRCH, TypeError # "PID is NOT running or is zombied
      false
    rescue Errno::EPERM
      $stderr.puts "No permission to query #{pid}!";
      false
    end

    def redirect_output!
      if log_path = options[:log]
        #puts "redirecting to log"
        # if the log directory doesn't exist, create it
        FileUtils.mkdir_p( File.dirname( log_path ), :mode => 0755 )
        # touch the log file to create it
        FileUtils.touch( log_path )
        # Set permissions on the log file
        File.chmod( 0644, log_path )
        # Reopen $stdout (NOT +STDOUT+) to start writing to the log file
        $stdout.reopen( log_path, 'a' )
        # Redirect $stderr to $stdout
        $stderr.reopen $stdout
        $stdout.sync = true
      else
        #puts "redirecting to /dev/null"
        # We're not bothering to sync if we're dumping to /dev/null
        # because /dev/null doesn't care about buffered output
        $stdin.reopen '/dev/null'
        $stdout.reopen '/dev/null', 'a'
        $stderr.reopen $stdout
      end
      log_path = options[:log] ? options[:log] : '/dev/null'
    end

  end
end
