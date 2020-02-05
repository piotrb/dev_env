# frozen_string_literal: true

module CommandHelpers
  def valid_commands
    methods.grep(/^cmd_/).map { |method| method.to_s.gsub(/^cmd_/, "") }
  end

  def dispatch_valid_commands(args)
    args = args.dup
    command = args.shift

    if valid_commands.include?(command)
      public_send("cmd_#{command}", args)
    else
      fail("unknown command: #{command.inspect}",
        "  valid commands: #{valid_commands.inspect}")
    end
  end

  def clean_env(type:, &block)
    backup = {}
    removed_keys = case type
                   when :ruby
                     ENV.keys.grep(/^(?:RBENV_|RUBYLIB)/)
                   else
                     raise ArgumentError, "unsupported type: #{type}"
    end

    removed_keys.each do |k|
      backup[k] = ENV[k]
    end

    removed_keys.each do |k|
      ENV.delete k
    end

    block.call
  ensure
    backup.each do |k, v|
      ENV[k] = v
    end
  end

  def log(message, depth: 0, newline: true)
    message = Array(message)
    message.each do |m|
      indent = "  " * depth
      print indent + m
      print "\n" if newline
    end
  end

  def run_with_each_line(cmd)
    Open3.popen2e(cmd) { |_stdin, stdout_and_stderr, wait_thr|
      pid = wait_thr.pid # pid of the started process.
      until stdout_and_stderr.eof?
        raw_line = stdout_and_stderr.gets
        yield(raw_line)
      end
      wait_thr.value # Process::Status object returned.
    }
  end

  def run_shell(command, return_status: false, echo_command: true, quiet: false)
    puts "$> #{command}" if echo_command
    command += " 1>/dev/null 2>/dev/null" if quiet
    system command.to_s
    code = $CHILD_STATUS.exitstatus
    raise("failed with code: #{code}") if !return_status && code > 0

    code
  end

  def capture_shell(command, error: true, echo_command: true)
    puts "<< #{command}" if echo_command
    command += " 2>/dev/null" unless error
    `#{command}`
  end

  def fail(*messages, code: 1)
    messages.each do |message|
      warn(message)
    end
    exit code
  end

  def need_gem(name, version_requirements = nil, require: name)
    begin
      gem name, version_requirements
    rescue Gem::MissingSpecError
      puts "Missing Gem: #{name} #{version_requirements}"
      print "Would you like to install it? (only `yes' will be accepted) => "
      input = gets.strip
      if input == "yes"
        puts "-> gem install #{name} #{version_requirements}"
        Gem.install name, version_requirements
        gem name, version_requirements
      else
        warn "Aborting!"
        exit 1
      end
    end

    Kernel.require require
  end

  # option_definitions
  # {
  #   name: string
  #   required?: boolean
  #   type?: class
  #   short?: string
  #   long?: string
  #   description?: string
  # }
  # if short and long are blank, name is used as long
  def parse_options(option_definitions, args)
    require "optparse"
    options = {}
    remaining_args = OptionParser.new { |opts|
      option_definitions.each do |od|
        opt_args = [
          od[:required] ? :REQUIRED : nil,
          od[:type],
          od[:short],
          od[:long],
          od[:short].nil? && od[:long].nil? ? od[:name] : nil,
          od[:description],
        ].compact
        opts.on(*opt_args) do |v|
          if od[:multiple]
            options[od[:name]] ||= []
            options[od[:name]] << v
          else
            options[od[:name]] = v
          end
        end
      end
    }.parse!(args)
    [remaining_args, options]
  end
end
