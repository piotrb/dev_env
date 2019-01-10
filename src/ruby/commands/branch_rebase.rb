require 'optparse'

require_relative "../lib/command_helpers"

module Commands
  module BranchRebase
    extend CommandHelpers

    class << self
      def run(args)
        dispatch_valid_commands(args)
      end

      def cmd_list(args)
        bases = bases_from_config
        ap bases
      end

      def cmd_add(args)
        bases = bases_from_config
        bases |= args
        save_bases_to_config(bases)
      end

      def cmd_remove(args)
        bases = bases_from_config
        bases.reject! { |n| args.include?(n) }
        save_bases_to_config(bases)
      end

      def cmd_rebase(args)
        options = {}
        OptionParser.new do |opts|
          opts.on("-i", "Interactive") do |v|
            options[:interactive] = v
          end
        end.parse!(args)

        fail("git is dirty") if git_dirty?
        tmp_branch = "#{branch_name}-base"

        run_shell "git fetch origin"

        begin
          if git_branch_exists?(tmp_branch)
            run_shell "git branch -D #{tmp_branch.inspect}"
          end
          run_shell "git checkout -b #{tmp_branch.inspect}"

          run_shell "git reset --hard origin/develop"
          bases = bases_from_config
          bases.each do |base|
            run_shell "git merge --no-edit origin/#{base}"
            run_shell "git rebase origin/develop"
          end
        ensure
          run_shell "git checkout #{branch_name.inspect}"
        end

        begin
          original_head = capture_shell("git rev-parse HEAD").strip
          run_shell "git rebase #{options[:interactive] ? "-i" : ""} #{tmp_branch.inspect} #{branch_name.inspect}"
        rescue
          run_shell "git rebase --abort"
          run_shell "git reset --hard #{original_head}"
        end
      end

      private

      def git_branch_exists?(name)
        capture_shell("git rev-parse --verify #{name.inspect}", error: false).strip != ""
      end

      def git_dirty?
        run_shell("git diff --stat head", quiet: true, return_status: true) > 0
      end

      def save_bases_to_config(new_bases)
        run_shell("git config branch.#{branch_name}.base-branches #{new_bases.join(",").inspect}")
      end

      def bases_from_config
        capture_shell("git config branch.#{branch_name}.base-branches", error: false).strip.split(",")
      end

      def branch_name
        @branch_name ||= capture_shell("git rev-parse --abbrev-ref HEAD").strip
      end
    end
  end
end