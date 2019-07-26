#!env ruby
require "erb"
require "fileutils"

TEMPLATE = <<-TEMPLATE
#!env ruby
<%= comment %>
require_relative '../src/ruby/init'
execute_command(<%= script_name.to_sym.inspect %>, ARGV)
TEMPLATE

Dir["commands/*.rb"].each do |cmd|
  ext = File.extname(cmd)
  script_name = File.basename(cmd, ext)
  exe_name = script_name.gsub("_", "-")
  if File.exist?("commands/#{script_name}.txt")
    comment = File.read("commands/#{script_name}.txt")
  else
    comment = ""
  end
  body = ERB.new(TEMPLATE).result(binding)
  puts "writing #{exe_name} ..."
  File.open("../../bin/#{exe_name}", "w") { |fh| fh.write(body) }
  FileUtils.chmod 0755, "../../bin/#{exe_name}"
end
