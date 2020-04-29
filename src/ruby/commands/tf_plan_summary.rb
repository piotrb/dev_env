# frozen_string_literal: true

module Commands
  module TfPlanSummary
    extend CommandHelpers

    class << self
      def init
        require "optparse"
        require "json"
        require_relative "../lib/ansi.rb"
        require_relative "../lib/terraform_helpers"

        extend TerraformHelpers
      end

      def run(args)
        options = {
          interactive: false,
          hierarchy: false,
        }

        args = OptionParser.new { |opts|
          opts.on("-i") do |v|
            options[:interactive] = v
          end
          opts.on("-h") do |v|
            options[:hierarchy] = v
          end
        }.parse!(args)

        if options[:interactive]
          raise "must specify plan file in interactive mode" if args[0].blank?
        end

        data = if args[0]
          load_summary_from_file(args[0])
        else
          JSON.parse(STDIN.read)
        end

        parts = []

        data["resource_changes"].each do |v|
          next unless v["change"]

          case v["change"]["actions"]
          when ["no-op"]
            # do nothing
          when ["create"]
            parts << {
              action: "create",
              address: v["address"],
              deps: find_deps(data, v["address"]),
            }
          when ["update"]
            parts << {
              action: "update",
              address: v["address"],
              deps: find_deps(data, v["address"]),
            }
          when ["delete"]
            parts << {
              action: "delete",
              address: v["address"],
              deps: find_deps(data, v["address"]),
            }
          when %w[delete create]
            parts << {
              action: "replace",
              address: v["address"],
              deps: find_deps(data, v["address"]),
            }
          when ["read"]
            parts << {
              action: "read",
              address: v["address"],
              deps: find_deps(data, v["address"]),
            }
          else
            puts "[??] #{v["address"]}"
            puts "UNKNOWN ACTIONS: #{v["change"]["actions"].inspect}"
            puts "TODO: update plan_summary to support this!"
          end
        end

        prune_unchanged_deps(parts)

        if options[:interactive]
          run_interactive(parts, args[0])
        else
          if options[:hierarchy]
            print_nested(parts)
          else
            print_flat(parts)
          end
          print_summary(parts)
        end
      end

      def load_summary_from_file(file)
        if File.exist?("#{file}.json") && File.mtime("#{file}.json").to_f >= File.mtime(file).to_f
          JSON.parse(File.read("#{file}.json"))
        else
          puts "Analyzing changes ..."
          result = tf_show(file, json: true)
          data = result.parsed_output
          File.open("#{file}.json", "w") { |fh| fh.write(JSON.dump(data)) }
          data
        end
      end

      def print_summary(parts)
        summary = {}
        parts.each do |part|
          summary[part[:action]] ||= 0
          summary[part[:action]] += 1
        end
        pieces = summary.map { |k, v|
          color = color_for_action(k)
          "#{Paint[v, :yellow]} to #{Paint[k, color]}"
        }

        puts
        puts "Plan Summary: #{pieces.join(Paint[", ", :gray])}"
      end

      def print_flat(parts)
        parts.each do |part|
          puts "[#{format_action(part[:action])}] #{format_address(part[:address])}"
        end
      end

      def run_interactive(parts, plan_name)
        prompt = TTY::Prompt.new
        result = prompt.multi_select("Update resources:", per_page: 99, echo: false) { |menu|
          parts.each do |part|
            label = "[#{format_action(part[:action])}] #{format_address(part[:address])}"
            menu.choice label, part[:address]
          end
        }

        if !result.empty?
          log "Re-running apply with the selected resources ..."
          status = tf_apply(targets: result)
          unless status.success?
            log Paint["Failed! (#{status.status})", :red]
            exit status.status
          end
        else
          raise "nothing selected"
        end
      end

      def print_nested(parts)
        parts = parts.deep_dup
        until parts.empty?
          part = parts.shift
          if part[:deps] == []
            indent = if part[:met_deps] && part[:met_deps].length > 0
              "  "
            else
              ""
            end
            message = "[#{format_action(part[:action])}]#{indent} #{format_address(part[:address])}"
            if part[:met_deps]
              message += " - (needs: #{part[:met_deps].join(", ")})"
            end
            puts message
            parts.each do |ipart|
              d = ipart[:deps].delete(part[:address])
              if d
                ipart[:met_deps] ||= []
                ipart[:met_deps] << d
              end
            end
          else
            parts.unshift part
          end
        end
      end

      def prune_unchanged_deps(parts)
        valid_addresses = parts.map { |part| part[:address] }

        parts.each do |part|
          part[:deps].select! { |dep| valid_addresses.include?(dep) }
        end
      end

      def find_config(module_root, module_name, address, parent_address)
        module_info = if parent_address.empty?
          module_root[module_name]
        elsif module_root && module_root[module_name]
          module_root[module_name]["module"]
        else
          {}
        end

        if m = address.match(/^module\.([^.]+)\./)
          find_config(module_info["module_calls"], m[1], m.post_match, parent_address + ["module.#{m[1]}"])
        else
          if module_info["resources"]
            resource = module_info["resources"].find { |resource|
              address == resource["address"]
            }
          end
          [resource, parent_address]
        end
      end

      def find_deps(data, address)
        result = []

        full_address = address
        m = address.match(/\[(.+)\]$/)
        if m
          address = m.pre_match
          index = m[1][0] == '"' ? m[1].gsub(/^"(.+)"$/, '\1') : m[1].to_i
        end

        if data["prior_state"]["values"]["root_module"]["resources"]
          resource = data["prior_state"]["values"]["root_module"]["resources"].find { |resource|
            address == resource["address"] && index == resource["index"]
          }
        end

        if resource && resource["depends_on"]
          result += resource["depends_on"]
        end

        resource, parent_address = find_config(data["configuration"], "root_module", address, [])
        if resource
          deps = []
          resource["expressions"].each do |k, v|
            if v.is_a?(Hash) && v["references"]
              deps << v["references"]
            end
          end
          result += deps.map { |s| (parent_address + [s]).join(".") }
        end

        result
      end

      def color_for_action(action)
        case action
        when "create"
          :green
        when "update"
          :yellow
        when "delete"
          :red
        when "replace"
          :red
        when "read"
          :cyan
        else
          :reset
        end
      end

      def symbol_for_action(action)
        case action
        when "create"
          "+"
        when "update"
          "~"
        when "delete"
          "-"
        when "replace"
          "±"
        when "read"
          ">"
        else
          action
        end
      end

      def format_action(action)
        color = color_for_action(action)
        symbol = symbol_for_action(action)
        Paint[symbol, color]
      end

      def format_address(address)
        parts = address.split(".")
        parts.each_with_index do |part, index|
          parts[index] = "#{ansi(:cyan)}#{part}#{ansi(:reset)}" if index.odd?
        end
        parts.join(".")
      end
    end
  end
end
