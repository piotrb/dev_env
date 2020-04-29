module TerraformHelpers
  def tf_force_unlock(id:)
    run_terraform(tf_prepare_command(["force-unlock", "-force", id], need_auth: true))
  end

  def tf_apply(filename: nil, targets: [])
    args = []
    args << filename if filename
    if targets && targets.length > 0
      targets.each do |target|
        args << "-target=${target}"
      end
    end

    cmd = tf_prepare_command(["apply", *args], need_auth: true)
    run_terraform(cmd)
  end

  def tf_validate
    cmd = tf_prepare_command(["validate", "-json"], need_auth: true)
    capture_terraform(cmd, json: true)
  end

  def tf_init(input: nil, upgrade: nil, color: true, &block)
    args = []
    args << "-input=#{input.inspect}" unless input.nil?
    args << "-upgrade" unless upgrade.nil?
    args << "-no-color" unless color

    cmd = tf_prepare_command(["init", *args], need_auth: true)
    stream_or_run_terraform(cmd, &block)
  end

  def tf_plan(out:, color: true, detailed_exitcode: nil, compact_warnings: false, input: nil, &block)
    args = []
    args += ["-out", out]
    args << "-input=#{input.inspect}" unless input.nil?
    args << "-compact-warnings" if compact_warnings
    args << "-no-color" unless color
    args << "-detailed-exitcode" if detailed_exitcode

    cmd = tf_prepare_command(["plan", *args], need_auth: true)
    stream_or_run_terraform(cmd, &block)
  end

  def tf_show(file, json: false)
    if json
      args = ["show", "-json", file]
      cmd = tf_prepare_command(args, need_auth: true)
      capture_terraform(cmd, json: true)
    else
      args = ["show", file]
      cmd = tf_prepare_command(args, need_auth: true)
      run_terraform(cmd)
    end
  end

  private

  def tf_prepare_command(args, need_auth:)
    if ENV["MUX_TF_AUTH_WRAPPER"] && need_auth
      words = Shellwords.shellsplit(ENV["MUX_TF_AUTH_WRAPPER"])
      [*words, "terraform", *args]
    else
      ["terraform", *args]
    end
  end

  def stream_or_run_terraform(args, &block)
    if block_given?
      stream_terraform(args, &block)
    else
      run_terraform(args)
    end
  end

  # return_status: false, echo_command: true, quiet: false, indent: 0
  def run_terraform(args, **options)
    status = run_shell(args, return_status: true, echo_command: true, quiet: false)
    OpenStruct.new({
      status: status,
      success?: status == 0,
    })
  end

  def stream_terraform(args, &block)
    status = run_with_each_line(args, &block)
    # status is a Process::Status
    OpenStruct.new({
      status: status.exitstatus,
      success?: status.exitstatus == 0,
    })
  end

  # error: true, echo_command: true, indent: 0, raise_on_error: false, detailed_result: false
  def capture_terraform(args, json: nil)
    result = capture_shell(args, error: true, echo_command: false, raise_on_error: false, detailed_result: true)
    if json
      parsed_output = JSON.parse(result.output)
    end
    OpenStruct.new({
      status: result.status,
      success?: result.status == 0,
      output: result.output,
      parsed_output: parsed_output,
    })
  rescue JSON::ParserError => e
    raise "Execution Failed! - #{result.inspect}"
  end
end
