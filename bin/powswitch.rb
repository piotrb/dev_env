#!/usr/bin/ruby
require "yaml"
require "fileutils"

command, = ARGV

global_config_file = File.expand_path("~/.powswitch")
global_config = File.exist?(global_config_file) ? YAML.load_file(global_config_file) : {}

config = global_config.merge(YAML.load_file(".powswitch"))
engine = config["engine"] || "pow"

def run(cmd)
  puts "$ #{cmd}"
  system(cmd) || exit($?.exitstatus)
end

powdir = case engine
         when "pow" then File.expand_path("~/.pow")
         when "puma-dev" then File.expand_path("~/.puma-dev")
         else
           raise "unknown engine: #{engine.inspect}"
         end

command ||= ""

default_name = File.basename(Dir.getwd)

config["links"] ||= [default_name]

case command.downcase
when "link"
  config["links"].each do |link|
    dst = powdir + "/#{link}"
    if File.exist?(dst)
      puts "rm: #{dst}"
      File.unlink(dst)
    end
    puts "ln -s: #{Dir.getwd}, #{dst}"
    FileUtils.ln_s(Dir.getwd, dst)
  end
when "proxy"
  config["links"].each do |link|
    dst = powdir + "/#{link}"
    if File.exist?(dst)
      puts "rm: #{dst}"
      File.unlink(dst)
    end
    puts "write: #{dst} -- #{config["port"].inspect}"
    File.open(dst, "w") { |fh| fh.write(config["port"]) }
  end
when "run"
  ENV["PORT"] = config["port"].to_s
  config["env"].each do |k, v|
    ENV[k] = v.to_s
  end if config["env"]
  system "foreman run web"
when "info"
  puts "config file help:"
  puts "  - links: Array<String> -- names of links to put in #{engine} directory"
  puts "  - port: Fixnum"
else
  $stderr.puts "invalid command: #{command.inspect}, valid: link, proxy, run"
  exit 1
end
