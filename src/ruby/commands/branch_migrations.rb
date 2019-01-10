require_relative "../lib/command_helpers"

module Commands
  module BranchMigrations
    extend CommandHelpers

    class << self
      def run(args)
        command = args.shift

        case command
        when "list"
          puts "Migrations in this branch:"
          list.sort.each do |file|
            puts " - #{file}"
          end
        when "undo"
          puts "Undoing migrations in this branch ..."
          list.sort.reverse.each do |file|
            version = File.basename(file)[/^\d+/]
            run_shell "bundle exec rake db:migrate:down VERSION=#{version}"
          end
        else
          $stderr.puts "unknown command: #{command.inspect}"
          $stderr.puts "  valid commands: list, undo"
          exit 1
        end
      end


      def list
        `git log --name-only --pretty="format:" develop..HEAD db/migrate`.split("\n").map(&:strip).reject(&:empty?)
      end
    end
  end
end