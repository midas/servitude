# Servitude

A set of tools for writing single or multi-threaded Ruby servers.


## Installation

Add this line to your application's Gemfile:

    gem 'servitude'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install servitude


## Usage

To build a server with Servitude only a couple of steps are required.

* Include the Servitude::Base module in the base module of your server project.
* Create a server class and include the Servitude::Server module (also include Servitude::ServerThreaded if you want multi-threaded server).
* Create a CLI class and include the Servitude::Cli module.
* If a single threaded server, implement your functionality in the Server#run method.
* If a multi-threaded server, implement your functionality in a handler class that includes the Servitude::Actor module and call the handler from the Server#run method.

For more details see the examples folder.

The rest of this document will discuss the functionality each module provides.

### Servitude::Actor

In order to achieve well abstracted multi-threaded functionality Servitude employs the [Celluloid](https://github.com/celluloid/celluloid) gem.  The actor module simply
abstracts some of the details of creating an actor away so you may concentrate on the functionality.  For example:

    module AwesomeServer
      class MessageHandler
        include Servitude::Actor

        def call( options )
          # some neat functionality ...
        end
      end
    end

While the #call method is not a Celluloid concept, in order to integrate with the Servitude::Server's default implementation, the #call method is the 
expected entry point to the actor.

The [Celluloid wiki](https://github.com/celluloid/celluloid/wiki) does a very good job of explaining the actor pattern.  In summary, an actor is a concurrent object
that runs in its own thread.

### Servitude::Base

The Base module provides core functionality for your Ruby server and should be inlcuded in the outermost namespace of your server project.  In addition to including
the Base module, you must call the ::boot method and provide the required arguments to it.  Note, the arguments for ::boot are Ruby "required keyword arguments"
and not a Hash.

If you do not call ::boot, an error is raised before your server can be started.

    module AwesomeServer
      include Servitude::Base

      boot host_namespace: AwesomeServer,
           app_id: 'awesome-server',
           app_name: 'Aswesome Server',
           company: 'Awesome, Inc.',
           default_config_path: "/etc/awesome/awesome-server.conf",
           default_log_path: "/var/log/awesome/awesome-server.log",
           default_pid_path: "/var/run/awesome/awesome-server.pid",
           default_thread_count: 1,
           version_copyright: "v#{VERSION} \u00A9#{Time.now.year} Awesome, Inc."
    end

### Servitude::Cli

The Cli module provides the functionality of a Command Line Interface for your server.

    module AwesomeServer
      class Cli
        include Servitude::Cli
      end
    end

In your CLI file (bin/awesome-server):

    #!/usr/bin/env ruby
    require 'awesome_server'
    AwesomeServer::Cli.new( ARGV ).run

### Servitude::Configuration

The Configuration module provides functionality for creating a configuration class.  You must call the ::configurations method and provide configuration
attributes to it.  The Configuration module also provides a ::from_file method that allows a configuration to be read from a JSON config file.

    module AwesomeServer
      class Configuration
        include Servitude::Configuration

        configurations :some_config,            # attribute with no default
                       [:another, 'some value'] # attribute with a default
      end
    end

If you want to load your configuration from a JSON config file you may do so by registering a callback (most likely an after_initialize callback).  If the
configuration file does not exist an error will be raised by Servitude.

    module AwesomeServer
      class Server
        include Servitude::Server
        
        after_initialize do
          Configuration.from_file( options[:config] )
        end

        # ...
      end
    end

### Servitude::Server

The Server module provides the base functionality for implementing a server, such as configuring the loggers, setting up Unix signal handling, outputting a 
startup banner, etc.  You must override the #run method in order to implement your functionality

    module AwesomeServer
      class Server
        include Servitude::Server

        def run
          info 'Running ...'
        end
      end
    end

#### Callbacks

The Server module provides callbacks to utilize in your server implementation:

* __before_initialize__: executes just before the initilaization of the server
* __after_initialize__: executes immediately after initilaization of the server
* __before_sleep__: executes just before the main thread sleeps to avoid exiting
* __finalize__: executes before server exits

You can provide one or more method names or procs to the callbacks to be executed.

    module AwesomeServer
      class Server
        after_initialize :configure_server

        finalize :cleanup

        finalize do
          info "Shutting down ..."
        end

      protected

        def configure_server
          # configuration code here ...
        end

        def cleanup
          # cleanup code here ...
        end
      end
    end

You can also define callbacks on your server and use them.  The callback/hook functionality is provided by the [hooks gem](https://github.com/apotonick/hooks).

    module AwesomeServer
      class Server    
        define_hook :before_run

        before_run do
          # do something ...
        end

        def run
          run_hook :before_run
          # do something ...
        end
      end
    end

### Servitude::ServerThreaded

The ServerThreaded module extends server functionality to be multi-threaded, providing several convenience methods to abstract away correctly handling certain 
situations Celluloid actors present.  The ServerThreaded module must be included after the Server module.

    module AwesomeServer
      class Server
        include Servitude::Server
        include Servitude::ServerThreaded
      end
    end

The ServerThreaded module assumes you will use the Celluloid actor pattern to implement your functionality.  Al you must do to implement the threaded functionality 
is override the #handler\_class method to specify the class that will act as your handler (actor) and utilize the #with_supervision block and 
\#call_handler_respecting_thread_count method providing the options to pass to your handler's #call method.

The #with_supervision block implements error handling/retry logic required to correctly interact with Celluloid supervision without bombing due to dead actor errors.

    module AwesomeServer
      class Server
        include Servitude::Server
        include Servitude::ServerThreaded

        def run
          some_event_generated_block do |event_args|
            with_supervision do
              call_handler_respecting_thread_count( info: event_args.info )
            end
          end
        end

        def handler_class
          AwesomeServer::MessageHandler
        end
      end
    end

The #some_event_generated_block method call in the code block above represents some even that happend that needs to be processed.  All servers sleep until an event 
happens and then do some work, respond and then go back to sleep.  Some good examples are receiving packets form a TCP/UDP socket or receiving a message from a 
message queue.
