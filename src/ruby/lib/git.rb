require_relative "./command_helpers"

module Git
  include CommandHelpers

  def current_branch
    capture_shell("git rev-parse --abbrev-ref HEAD", echo_command: false).strip
  end

  def get_config(name)
    capture_shell("git config #{name.inspect}", echo_command: false, error: false).strip
  end

  def set_config(name, value)
    run_shell("git config #{name.inspect} #{value.inspect}")
  end

  def dirty?
    run_shell("git diff --stat head", quiet: true, echo_command: false, return_status: true) > 0
  end

  def branch_exists?(name)
    capture_shell("git rev-parse --verify #{name.inspect}", error: false, echo_command: false).strip != ""
  end

  def delete_branch(name, force: false)
    flag = force ? "-D" : "-d"
    run_shell("git branch #{flag} #{name.inspect}")
  end

  def fetch(remote, quiet: false)
    run_shell("git fetch #{remote.inspect}", quiet: quiet)
  end

  def checkout(ref = nil, to_branch: nil, quiet: false)
    cmd = [
      "git checkout",
      quiet ? "-q" : nil,
      ref ? ref.inspect : nil,
      to_branch ? "-b #{to_branch}" : nil,
    ]
    run_shell cmd.compact.join(" ")
  end

  def rebase(upstream, branch = nil, interactive: false, return_status: false)
    cmd = [
      "git rebase",
      interactive ? "-i" : nil,
      upstream ? upstream.inspect : nil,
      branch ? branch.inspect : nil,
    ]
    run_shell cmd.compact.join(" "), return_status: return_status
  end

  def merge(ref, ff: nil, edit: nil)
    cmd = [
      "git merge",
      ff.nil? ? nil : (ff ? "--ff" : "--no-ff"),
      edit.nil? ? nil : (edit ? "--edit" : "--no-edit"),
      ref.inspect,
    ]
    run_shell cmd.compact.join(" "), quiet: true
  end

  def reset(ref, hard: false)
    cmd = [
      "git reset",
      hard ? "--hard" : nil,
      ref.inspect,
    ]
    run_shell cmd.compact.join(" ")
  end

  extend self
end
