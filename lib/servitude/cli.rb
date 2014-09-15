require 'rubygems'
require 'servitude'
require 'thor'
require 'yell'


module Servitude
  module Cli

    autoload :Base,    'servitude/cli/base'
    autoload :Service, 'servitude/cli/service'

  end
end
