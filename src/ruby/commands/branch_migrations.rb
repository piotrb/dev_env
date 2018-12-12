module Commands
  module BranchMigrations
    class << self
      def run(args)
        command = args.shift

        case command
        when "list"
          
        else
          raise "unknown command: #{command.inspect}"
        end
      end
    end
  end
end