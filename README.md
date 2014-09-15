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

For executable examples see the [examples folder](https://github.com/midas/servitude/tree/master/examples).  To run the examples, clone the project, 
install the bundle and follow the usage instructions in each example.

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

The Cli module provides several classes with Command Line Interface functionality for your server.  The Cli::Service class provides standard unix service
sub-commands: start, stop, status and restart.

    module AwesomeServer
      class Cli < Servitude::Cli::Service
      end
    end

In your CLI file (bin/awesome-server):

    #!/usr/bin/env ruby
    require 'awesome_server'
    AwesomeServer::Cli.start

To build a custom CLI, you can inherit from Cli::Base.

    module AwesomeServer
      class Cli < Servitude::Cli::Base
      end
    end

For details on how to add commands to your custom or standard service CLIs see the [Thor documentation](http://whatisthor.com/).


### Servitude::Configuration

All Servitude servers automatically have a configuration instantiated for them (although it may be empty).  The default class for the configuration is
Servitude::Configuration.  In order to define a custom configuration, define a custom configuraiton class (which may inherit from Servitude::Configuration)
and simply override the Servitude::Server#configuration method in your Server class.  Be sure the custom configuration calss accepts the command line
options and passes them to the super class's initializer or configuration will be completely broken.

    module AwesomeServer
      class Configuration < Servitude::Configuration
        def initialize( cli_options )
          super( cli_options )
          # possibly do something else ...
        end
      end

      class Server
        include Servitude::Server

        def configuration_class
          AwesomeServer::Configuration
        end
      end
    end

The Servitude::Configuration class delegates to a [Hashie::Mash](https://github.com/intridea/hashie#mash) backend, which gives it great flexibiltiy.
Any Hash or JSON like structure can be passed directly into the configuration and work.  Thus, one does not have to explicitly define the configuration 
attributes as the configuration will represent exactly what is in the JSON config file.  In addition, the command line options are passed into the 
configuration and merged to the configuration that came from a config file (if there is a config file).  The merge results in the command line options 
overriding any matching file configurations.

For example, given a config file:

    {
      "key1": "value1",
      "log_level": "info",
      "envs": {
        "development": {
          "key2": "value2",
        },
        "production": {
          "key2": "value3",
        }
      }
    }

And command line options of:

    $ awesome-server start --interactive --log_level debug

The configuration result will be:

    {
      "key1": "value1",
      "log_level": "debug",
      "interactive": true,
      "envs": {
        "development": {
          "key2": "value2",
        },
        "production": {
          "key2": "value3",
        }
      }
    }

Notice the log_level has been overridden to the command line option value instead of the file value.  Because the command line options are an inherently
flass structure, any config file options that should be overridden should be at the first level of the JSON structure.

Because Hashie::Mash is the backend for the configuration values may be accessed using a hash notation or an object notation.

    config['key1'] # => "value1"
    config[:key1]  # => "value1"
    config.key1    # => "value1"

    config['development']['key2'] # => "value2"
    config[:development][:key2]   # => "value2"
    config.development.key2       # => "value2"

The startup banner for a Servitude server automatically outputs the ocnfiguration options in a dot notation format.  Continuing our configuraiton example,
the smart banner would look like:

    ***
    * Awesome Server started
    *
    * v1.0.0 ©2014 Awesome Company
    *
    * Configuration
    *  config: /Users/cjharrelson/development/personal/gems/servitude/config/echo-server.conf
    *  log_level: debug
    *  log: STDOUT
    *  pid: /Users/cjharrelson/development/personal/gems/servitude/tmp/echo-server.pid
    *  threads: 1
    *  key1: value1
    *  envs.development.key2: value2
    *  envs.production.key2: value3
    *
    ***

You may notice the absence of the interactive value.  This is due to filtering built into the start banner output.  Several values are already in the 
default_config_filters that are a result of the Trollop implementation of the command line option parsing.  If you would like to add additional keys 
to be filterd, override the config_filters method in your server class and provide an array of keys (in dot notation) to filter.

    module AwesomeServer
      class Server
        ...
        def config_filters
          %w(
            key1
            envs.development.key2
          )
        end
        ...
      end
    end

### Servitude::EnvironmentConfiguration

Building upon Servitude::Configuration, the EnvironmentConfiguration adds the concept of environments to configuration.  In order to use 
EnvironmentConfiguration override #configuration_class in your server class.

    module AwesomeServer
      class Server
        include Servitude::Server

        def configuration_class
          Servitude::EnvironmentConfiguration
        end
      end
    end

The command line can except and --environment (-e) switch, although it is not required.  If using config file and environemnt, a best practice is to put
the default environment in your config file so there is a default environment.

    {
      "environment": "development",
      "development": {
        ...
      },
      "production": {
        ...
      }
    }


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
* __before_run__: executes just before the run method is called
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
