# frozen_string_literal: true

module Commands
  module TfCurrent
    extend CommandHelpers

    PLAN_FILENAME = "foo.tfplan"

    class << self
      def init
        require "open3"
        require "shellwords"
        require_relative "../lib/stateful_parser"
        require_relative "../lib/terraform_helpers"
        require_relative "../lib/tf_current/plan_formatter"
        require_relative "../lib/cmd_loop"
        require_relative "../lib/cri_command_support"

        extend CmdLoop
        extend CriCommandSupport
        extend TerraformHelpers
      end

      def run(args)
        if args[0] == "cli"
          cmd_loop
          return
        end

        folder_name = File.basename(Dir.getwd)
        log "Processing #{Paint[folder_name, :cyan]} ..."

        ENV["TF_IN_AUTOMATION"] = "1"
        ENV["TF_INPUT"] = "0"

        return launch_cmd_loop(:error) unless prepare_folder

        if ENV["TF_UPGRADE"]
          upgrade_status, upgrade_meta = run_upgrade
          return launch_cmd_loop(:error) unless upgrade_status == :ok
        end

        plan_status, @plan_meta = create_plan(PLAN_FILENAME)

        case plan_status
        when :ok
          log "no changes, exiting", depth: 1
        when :error
          log "something went wrong", depth: 1
          launch_cmd_loop(plan_status)
        when :changes
          log "Printing Plan Summary ...", depth: 1
          pretty_plan_summary(PLAN_FILENAME)
          launch_cmd_loop(plan_status)
        when :unknown
          launch_cmd_loop(plan_status)
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        puts Paint["Unhandled Exception!", :red]
        puts "=" * 20
        puts e.full_message
        puts
        puts "< press enter to continue >"
        gets
        exit 1
      end

      def pretty_plan_summary(filename)
        run_with_each_line(["tf-plan-summary", filename]) do |raw_line|
          log raw_line.rstrip, depth: 2
        end
      end

      def create_plan(filename)
        log "Preparing Plan ...", depth: 1
        exit_code, meta = ::TfCurrent::PlanFormatter.pretty_plan(filename)
        case exit_code
        when 0
          [:ok, meta]
        when 1
          [:error, meta]
        when 2
          [:changes, meta]
        else
          log Paint["terraform plan exited with an unknown exit code: #{exit_code}", :yellow]
          [:unknown, meta]
        end
      end

      def run_plan
        plan_status, @plan_meta = create_plan(PLAN_FILENAME)

        case plan_status
        when :ok
          log "no changes", depth: 1
        when :error
          log "something went wrong", depth: 1
        when :changes
          log "Printing Plan Summary ...", depth: 1
          pretty_plan_summary(PLAN_FILENAME)
        when :unknown
          # nothing
        end
      end

      def plan_cmd
        define_cmd("plan", summary: "Re-run plan") do |opts, args, cmd|
          run_plan
        end
      end

      def force_unlock_cmd
        define_cmd("force-unlock", summary: "Force unlock state after encountering a lock error!") do
          prompt = TTY::Prompt.new(interrupt: :noop)

          table = TTY::Table.new(header: ["Field", "Value"])
          table << ["Lock ID", @plan_meta["ID"]]
          table << ["Operation", @plan_meta["Operation"]]
          table << ["Who", @plan_meta["Who"]]
          table << ["Created", @plan_meta["Created"]]

          puts table.render(:unicode, padding: [0, 1])

          if @plan_meta && @plan_meta["error"] == "lock"
            done = catch(:abort) {
              if @plan_meta["Operation"] != "OperationTypePlan"
                throw :abort unless prompt.yes?(
                  "Are you sure you want to force unlock a lock for operation: #{@plan_meta["Operation"]}",
                  default: false
                )
              end

              throw :abort unless prompt.yes?(
                "Are you sure you want to force unlock this lock?",
                default: false
              )

              status = tf_force_unlock(id: @plan_meta["ID"])
              if status.success?
                log "Done!"
              else
                log Paint["Failed with status: #{status}", :red]
              end

              true
            }

            unless done
              log Paint["Aborted", :yellow]
            end
          else
            log Paint["No lock error or no plan ran!", :red]
          end
        end
      end

      def shell_cmd
        define_cmd("shell", summary: "Open your default terminal in the current folder") do |opts, args, cmd|
          log Paint["Launching shell ...", :yellow]
          log Paint["When it exits you will be back at this prompt.", :yellow]
          system ENV["SHELL"]
        end
      end

      def apply_cmd
        define_cmd("apply", summary: "Apply the current plan") do |opts, args, cmd|
          status = tf_apply(filename: PLAN_FILENAME)
          if status.success?
            throw :stop, :done
          else
            log "Apply Failed!"
          end
        end
      end

      def upgrade_cmd
        define_cmd("upgrade", summary: "Upgrade modules/plguins") do |opts, args, cmd|
          status, meta = run_upgrade
          if status != :ok
            log meta.inspect if meta.length > 0
            log "Upgrade Failed!"
          end
        end
      end

      def interactive_cmd
        define_cmd("interactive", summary: "Apply interactively") do |opts, args, cmd|
          status = run_shell(["tf-plan-summary", PLAN_FILENAME, "-i"], return_status: true)
          if status != 0
            log "Interactive Apply Failed!"
          else
            run_plan
          end
        end
      end

      def build_root_cmd
        root_cmd = define_cmd(nil)

        root_cmd.add_command(plan_cmd)
        root_cmd.add_command(apply_cmd)
        root_cmd.add_command(shell_cmd)
        root_cmd.add_command(force_unlock_cmd)
        root_cmd.add_command(upgrade_cmd)
        root_cmd.add_command(interactive_cmd)

        root_cmd.add_command(exit_cmd)
        # root_cmd.add_command(Cri::Command.define {
        #   name "dostuff"
        #   usage "dostuff [options]"
        #   aliases :ds, :stuff
        #   summary "does stuff"
        #   description "This command does a lot of stuff. I really mean a lot."

        #   flag :h, :help, "show help for this command" do |value, cmd|
        #     puts cmd.help
        #   end
        #   flag nil, :more, "do even more stuff"
        #   option :s, :stuff, "specify stuff to do", argument: :required

        #   run do |opts, args, cmd|
        #     stuff = opts.fetch(:stuff, "generic stuff")
        #     puts "Doing #{stuff}!"

        #     if opts[:more]
        #       puts "Doing it even more!"
        #     end
        #   end
        # })
        root_cmd
      end

      def cmd_loop(status = nil)
        root_cmd = build_root_cmd

        folder_name = File.basename(Dir.getwd)

        puts root_cmd.help

        prompt = "#{folder_name} => "
        case status
        when :error, :unknown
          prompt = "[#{Paint[status.to_s, :red]}] #{prompt}"
        when :changes
          prompt = "[#{Paint[status.to_s, :yellow]}] #{prompt}"
        end

        run_cmd_loop(prompt) { |cmd|
          throw(:stop, :no_input) if cmd == ""
          args = Shellwords.split(cmd)
          root_cmd.run(args, {}, hard_exit: false)
        }
      end

      def launch_cmd_loop(status)
        return if ENV["NO_CMD"]
        case status
        when :error, :unknown
          log Paint["Dropping to command line so you can fix the issue!", :red]
        when :changes
          log Paint["Dropping to command line so you can review the changes.", :yellow]
        end
        cmd_loop(status)
      end

      def prepare_folder
        remedies = ::TfCurrent::PlanFormatter.process_validation(validate)
        process_remedies(remedies)
      end

      def run_upgrade
        exit_code, meta = ::TfCurrent::PlanFormatter.process_upgrade
        case exit_code
        when 0
          [:ok, meta]
        when 1
          [:error, meta]
        # when 2
        #   [:changes, meta]
        else
          log Paint["terraform init upgrade exited with an unknown exit code: #{exit_code}", :yellow]
          [:unknown, meta]
        end
      end

      def validate
        log "Validating module ...", depth: 1
        tf_validate.parsed_output
      end

      def process_remedies(remedies)
        if remedies.delete? :init
          log "Running terraform init ...", depth: 2
          tf_init
          remedies = ::TfCurrent::PlanFormatter.process_validation(validate)
          process_remedies(remedies)
        end
        unless remedies.empty?
          log "unprocessed remedies: #{remedies.to_a}", depth: 1
          return false
        end
        true
      end
    end
  end
end
