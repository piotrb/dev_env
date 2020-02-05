# frozen_string_literal: true

require "English"
require "yaml"

require_relative "lib/method_import"
require_relative "lib/command_helpers"

import :need_gem, from: CommandHelpers

need_gem "activesupport", require: "active_support/all"

def load_deps(name)
  fn = File.expand_path("deps/#{name}.yml", __dir__)
  return unless File.exist?(fn)
  dep_info = YAML.load_file(fn)

  dep_info["gems"]&.each do |args|
    need_gem(*args)
  end
end

def execute_command(name, args)
  load_deps(name)

  require_relative "commands/#{name}"
  klass = "Commands::#{name.to_s.camelcase}".constantize
  klass.init if klass.respond_to? :init
  klass.run(args)
end
