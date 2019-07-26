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

  def run_shell(command, return_status: false, echo_command: true, quiet: false)
    puts "$> #{command}" if echo_command
    command += " 1>/dev/null 2>/dev/null" if quiet
    system "#{command}"
    code = $?.exitstatus
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
      $stderr.puts(message)
    end
    exit code
  end
end
