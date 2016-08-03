#!/usr/bin/ruby
has_bundle = File.exists?("Gemfile")
is_compatible_app = (File.exists?("config/application.rb") || File.exists?("config/spring.rb")) && File.exists?(".spring")
has_spring_in_bundle = `bundle list`.split("\n").grep(/spring/).any?

if ARGV.size < 1
  STDERR.puts "must specify a command"
  exit 1
end

if is_compatible_app && ((has_bundle && has_spring_in_bundle) || !has_bundle)
  system "bundle", ["exec", "spring"] + ARGV
else
  if File.exists?("Gemfile")
    system "bundle", ["exec"] + ARGV
  else
    command = ARGV.shift
    system command, ARGV
  end
end
