# frozen_string_literal: true

module Commands
  module TfSmartMove
    extend CommandHelpers

    class << self
      def init
        require "optparse"
        require "json"
      end

      # tf-smart-move foo.tfplan 'module.$1.$2.$T' '$2.$T["$1"]' -t user:imported_user -t groups:imported_user -t login:imported_user -t ssh:imported_user
      def run(args)
        options = {
          translate: [],
        }

        args = OptionParser.new { |opts|
          opts.on("-t=") do |v|
            options[:translate] << v.split(":")
          end
        }.parse!(args)

        plan_file, from_pattern, to_pattern = args

        raise "must specify plan file" if plan_file.blank?
        raise "must specify from" if from_pattern.blank?
        raise "must specify to" if to_pattern.blank?

        conversion_reg = [/\\\$(.)/, '(?<M\1>.+)']

        from_regexp = Regexp.new("^" + Regexp.escape(from_pattern).gsub(*conversion_reg) + "$")
        to_regexp = Regexp.new("^" + Regexp.escape(to_pattern).gsub(*conversion_reg) + "$")

        data = JSON.parse(`terraform show -json #{args[0].inspect}`)

        removed_items = []
        added_items = []

        data["resource_changes"].each do |v|
          next unless v["change"]

          case v["change"]["actions"]
          when ["create"]
            added_items << v["address"]
          when ["delete"]
            removed_items << v["address"]
          end
        end

        rl = removed_items.map { |i| i.match(from_regexp) }.compact
        al = added_items.map { |i| i.match(to_regexp) }.compact

        moves = []

        rl.each do |removed|
          al.each do |added|
            capture_keys = removed.named_captures.keys - ["MT"]

            matching = capture_keys.all? { |k| removed[k] == added[k] }
            if matching && options[:translate].present?
              matching = options[:translate].any? { |t_from, t_to|
                removed["MT"] == t_from && added["MT"] == t_to
              }
            end

            moves << [removed, added] if matching
          end
        end

        moves.each do |removed, added|
          puts "terraform state mv #{removed[0].inspect} #{added[0].inspect}"
        end
      end
    end
  end
end
