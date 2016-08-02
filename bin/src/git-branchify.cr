#!/usr/bin/env ruby

def sh(cmd)
  puts "$ #{cmd}"
  system(cmd) || raise("command failed: #{$?.exit_status}")
end

require "option_parser"

options = {} of Symbol => Bool

OptionParser.new do |opts|
  opts.banner = "Usage: git-branchify [options]"

  opts.on("-f", "--feature", "Create as a Feature branch") do |v|
    options[:feature] = !!v
  end

  opts.on("-e", "--epic", "Create as an Epic branch") do |v|
    options[:epic] = !!v
  end

  opts.on("--hotfix", "Create a a hotfix branch") do |v|
    options[:hotfix] = !!v
  end

  opts.on("-s", "--sub", "Create a sub branch (current-new name)") do |v|
    options[:sub] = !!v
  end

end.parse!

if ARGV.empty?
  name = STDIN.read_line
else
  name = ARGV.join(" ")
end

name = name.downcase.gsub(/[^a-z0-9]/, ' ').gsub(/ +/, " ").strip.gsub(" ", "-")

if options[:sub]
  current_branch = `git rev-parse --symbolic-full-name --abbrev-ref HEAD`.strip
  current_branch = current_branch.split("/").last
  name = "#{current_branch}-#{name}"
end

if options[:feature]
  name = "feature/#{name}"
end

if options[:epic]
  name = "epic/#{name}"
end

if options[:hotfix]
  name = "hotfix/#{name}"
end

sh "git checkout -b #{name.inspect}"
sh "git config branch.#{name}.remote origin"
sh "git config branch.#{name}.merge refs/heads/#{name}"
