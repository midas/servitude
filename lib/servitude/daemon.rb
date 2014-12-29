require 'fileutils'
require 'servitude'
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
      @name     = options[:name] || Servitude::APP_NAME
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
      Servitude::server_class.new( options ).start
    end

    def stop
      case kill_process
        when :success
          remove_pid
        when :failed_to_stop
        when :does_not_exist
          puts "#{Servitude::APP_NAME} process is not running"
          prompt_and_remove_pid_file if pid_file_exists? && !options[:quiet]
        else
          raise 'Unknown return code from #kill_process'
      end
    end

    def status
      if process_exists?
        puts "#{Servitude::APP_NAME} process running with PID: #{pid}"
        true
      else
        puts "#{Servitude::APP_NAME} process does not exist"
        prompt_and_remove_pid_file if pid_file_exists? && !options[:quiet]
        false
      end
    end

  protected

    def prompt_and_remove_pid_file
      $stdout.write "PID file still exists at '#{pid_path}'. Remove it [y/N]? "
      answer = $stdin.gets.strip
      if answer =~ /^y(es)?$/i
        remove_pid
        puts "Removed PID file"
      end
    end

    def remove_pid
      FileUtils.rm( pid_path ) if File.file?( pid_path )
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
      pid = begin
              File.read( pid_path ).chomp
            rescue Errno::ENOENT # No such file or directory
              return nil
            rescue Errno::EACCES # Permission denied
              $stderr.puts "No permission to read #{pid_path}"
              return nil
            rescue => e
              $stderr.puts "Unable to read #{pid_path}\n\t(#{e.class.name}) #{e.message}"
              return nil
            end

      return pid.to_i if ( pid =~ /^[1-9][0-9]*$/ )

      $stderr.puts "#{pid_path} does not contain a PID"
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

      $stdout.write "Attempting to stop #{Servitude::APP_NAME} process #{pid}..."
      Process.kill INT, pid

      iteration_num = 0
      while process_exists? && iteration_num < 10
        sleep 1
        $stdout.write "."
        iteration_num += 1
      end

      if process_exists?
        $stderr.puts "\nFailed to stop #{Servitude::APP_NAME} process #{pid}"
        return :failed_to_stop
      else
        $stdout.puts "\nSuccessfuly stopped #{Servitude::APP_NAME} process #{pid}"
      end

      return :success
    rescue Errno::EPERM
      $stderr.puts "No permission to query #{pid}!";
    end

    def pid_file_exists?
      File.file? pid_path
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
    rescue => e
      $stderr.puts "Unable to query #{pid}\n\t(#{e.class.name}) #{e.message}"
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
