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
        require_relative "../lib/tf_current/plan_formatter"
        require_relative "../lib/cmd_loop"
        require_relative "../lib/cri_command_support"

        extend CmdLoop
        extend CriCommandSupport
      end

      def run(args)
        if args[0] == "cli"
          cmd_loop
          return
        end

        folder_name = File.basename(Dir.getwd)
        log "Processing #{Paint[folder_name, :cyan]} ..."

        ENV["TF_IN_AUTOMATION"] = "1"

        return launch_cmd_loop(:error) unless prepare_folder

        plan_status = create_plan(PLAN_FILENAME)

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
        run_with_each_line("tf-plan-summary #{filename.inspect}") do |raw_line|
          log raw_line.rstrip, depth: 2
        end
      end

      def create_plan(filename)
        log "Preparing Plan ...", depth: 1
        exit_code = ::TfCurrent::PlanFormatter.pretty_plan(filename)
        case exit_code
        when 0
          :ok
        when 1
          :error
        when 2
          :changes
        else
          log Paint["terraform plan exited with an unknown exit code: #{exit_code}", :yellow]
          :unknown
        end
      end

      def plan_cmd
        define_cmd("plan") do |opts, args, cmd|
          plan_status = create_plan(PLAN_FILENAME)

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
      end

      def shell_cmd
        define_cmd("shell") do |opts, args, cmd|
          log Paint["Launching shell ...", :yellow]
          log Paint["When it exits you will be back at this prompt.", :yellow]
          system ENV["SHELL"]
        end
      end

      def apply_cmd
        define_cmd("apply") do |opts, args, cmd|
          status = run_shell("terraform apply #{PLAN_FILENAME.inspect}", return_status: true)
          if status == 0
            throw :stop, :done
          else
            log "Apply Failed!"
          end
        end
      end

      def build_root_cmd
        root_cmd = define_cmd(nil)

        root_cmd.add_command(plan_cmd)
        root_cmd.add_command(apply_cmd)
        root_cmd.add_command(shell_cmd)

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

      def validate
        log "Validating module ...", depth: 1
        JSON.parse(`terraform validate -json`)
      end

      def process_remedies(remedies)
        if remedies.delete? :init
          log "Running terraform init ...", depth: 2
          system("terraform init -input=false")
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
