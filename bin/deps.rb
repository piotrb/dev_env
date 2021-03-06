#!env ruby
require "yaml"
require "json"

args = ARGV.dup
command = args.size > 0 ? args.shift : nil

def usage
  puts "usage:"
  puts "  deps (command)"
  puts ""
  puts "valid commands:"
  puts "  list"
  puts "  status"
  puts "  start [service]"
  puts "  stop [service]"
end

def deps
  if File.exists?(".deps.yml")
    YAML.parse(File.read(".deps.yml")) || [] of String
  else
    STDERR.puts "can't find .deps.yml"
    exit 1
  end
end

def run(cmd)
  puts "$ #{cmd}"
  cmd = "#{cmd} 2>&1"
  system(cmd)
  raise "command failed: #{$?.exit_status}" unless $?.success?
end

def bt(cmd)
  data = `#{cmd} 2>&1`
  raise data unless $?.success?
  data
end

def all_statuses
  data = {} of String => { pid: Int32 | Nil, exit_code: Int32, status: Symbol }
  bt("launchctl list").split("\n").each do |line|
    pid, exit_code, name = line.strip.split("\t")
    exit_code = exit_code.to_i
    pid = (pid == '-') ? nil : pid.to_i
    data[name] = {
      pid: pid,
      exit_code: exit_code,
      status: pid ? :running : :stopped,
    }
  end
  data
end

def validate_dep(dep)
  unless deps.includes?(dep)
    STDERR.puts "#{dep} is not a valid dep"
    exit 1
  end
  dep
end

def dep_to_file(dep)
  fn = Dir["/usr/local/opt/#{dep}/*.plist"].first
  raise "Could not find file for dep: #{dep}" unless fn
  fn
end

def parse_plist(fn)
  JSON.parse(bt("plutil -convert json #{fn.inspect} -o -"))
end

def dep_to_name(dep)
  file = dep_to_file(dep)
  plist = parse_plist(file)
  plist["Label"]
end

def deps_from_args(dep)
  dep ? [validate_dep(dep)] : deps
end

case command
when "list"
  puts "Project Deps:"
  deps.each do |dep|
    puts "- #{dep}"
  end
when "status"
  puts "Dep Status:"
  deps.each do |dep|
    name = dep_to_name(dep)
    if all_statuses[name]
      puts "#{dep} - #{all_statuses[name][:status]}"
    else
      puts "#{dep} - not loaded"
    end
  end
when "stop"
  dep = args.shift

  deps_from_args(dep).each do |dep_name|
    name = dep_to_name(dep_name)
    if all_statuses[name]
      run "launchctl unload #{dep_to_file(dep).inspect}"
    else
      puts "#{dep_name} is already unloaded"
    end
  end
when "start"
  dep = args.shift

  deps_from_args(dep).each do |dep_name|
    name = dep_to_name(dep_name)
    if all_statuses[name]
      puts "#{dep_name} is already loaded"
    else
      run "launchctl load #{dep_to_file(dep).inspect}"
    end
  end
else
  usage
end
