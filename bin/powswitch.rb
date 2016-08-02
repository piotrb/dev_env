#!/usr/bin/ruby
require 'yaml'
require 'fileutils'

command, = ARGV

config = YAML.load_file(".powswitch")

def run(cmd)
  puts "$ #{cmd}"
  system(cmd) || exit($?.exitstatus)
end

powdir = File.expand_path('~/.pow')

command ||= ""

case command.downcase
when 'link'
  config['links'].each do |link|
    dst = powdir + "/#{link}"
    if File.exist?(dst)
      puts "rm: #{dst}"
      File.unlink(dst)
    end
    puts "ln -s: #{Dir.getwd}, #{dst}"
    FileUtils.ln_s(Dir.getwd, dst)
  end
when 'proxy'
  config['links'].each do |link|
    dst = powdir + "/#{link}"
    if File.exist?(dst)
      puts "rm: #{dst}"
      File.unlink(dst)
    end
    puts "write: #{dst} -- #{config['port'].inspect}"
    File.open(dst, 'w') { |fh| fh.write(config['port']) }
  end
when 'run'
  ENV['PORT'] = config['port'].to_s
  config['env'].each do |k, v|
    ENV[k] = v.to_s
  end if config['env']
  system "foreman run web"
else
  $stderr.puts "invalid command: #{command.inspect}, valid: link, proxy, run"
  exit 1
end
