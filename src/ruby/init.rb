require "active_support/all"
require "shellwords"
require "ap"
require "yaml"
require "pry"
require 'English'

def execute_command(name, args)
  require_relative "commands/#{name}"
  "Commands::#{name.to_s.camelcase}".constantize.run(args)
end
