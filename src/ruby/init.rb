require 'active_support/all'

def execute_command(name, args)
  require_relative "commands/#{name}"
  "Commands::#{name.to_s.camelcase}".constantize.run(args)
end
