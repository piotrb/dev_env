# frozen_string_literal: true

require "English"

require_relative "lib/command_helpers"

need_gem = CommandHelpers.instance_method(:need_gem).bind(self)
need_gem.call("activesupport", require: "active_support/all")

def execute_command(name, args)
  require_relative "commands/#{name}"
  klass = "Commands::#{name.to_s.camelcase}".constantize
  klass.init if klass.respond_to? :init
  klass.run(args)
end
