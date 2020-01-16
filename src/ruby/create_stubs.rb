#!env ruby
require "erb"
require "fileutils"

puts "Detecting Environment ..."
env_location = `which env`.strip
puts "env: #{env_location}"

TEMPLATE = <<~TEMPLATE
  #!#{env_location} ruby
  <%= comment %>
  require_relative '../src/ruby/init'
  execute_command(<%= script_name.to_sym.inspect %>, ARGV)
TEMPLATE

puts ""
puts "Updating stubs ..."

Dir["commands/*.rb"].each do |cmd|
  ext = File.extname(cmd)
  script_name = File.basename(cmd, ext)
  exe_name = script_name.tr("_", "-")
  comment = if File.exist?("commands/#{script_name}.txt")
    File.read("commands/#{script_name}.txt")
  else
    ""
  end
  body = ERB.new(TEMPLATE).result(binding)
  puts "writing #{exe_name} ..."
  File.open("../../bin/#{exe_name}", "w") { |fh| fh.write(body) }
  FileUtils.chmod 0o755, "../../bin/#{exe_name}"
end
