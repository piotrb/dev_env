require 'json'

require_relative "../lib/ansi.rb"

module Commands
  module PlanSummary
    class << self
      def run(args)
        data = JSON.parse(STDIN.read)

        data["resource_changes"].each do |v|
          if v["change"]
            case v["change"]["actions"]
            when ["no-op"]
              # puts "[noop] #{v["address"]}"
            when ["update"]
              puts "[#{ansi(:yellow)}~#{ansi(:reset)}] #{format_address(v["address"])}"
            else
              puts "[??] #{v["address"]}"
              puts "UNKNOWN ACTIONS: #{v["change"]["actions"].inspect}"
              puts "TODO: update plan_summary to support this!"
              # p v["change"].keys
            end
          end
        end
      end

      def format_address(address)
        parts = address.split(".")
        parts.each_with_index { |part, index|
          if index % 2 == 1
            parts[index] = "#{ansi(:cyan)}#{part}#{ansi(:reset)}"
          end
        }
        parts.join(".")
      end
    end
  end
end
