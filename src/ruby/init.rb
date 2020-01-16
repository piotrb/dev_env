require "active_support/all"
require "shellwords"
require "ap"
require "yaml"
# require "pry"
require "English"

def execute_command(name, args)
  require_relative "commands/#{name}"
  klass = "Commands::#{name.to_s.camelcase}".constantize
  klass.init if klass.respond_to? :init
  klass.run(args)
end
