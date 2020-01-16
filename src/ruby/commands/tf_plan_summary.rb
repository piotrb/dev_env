# frozen_string_literal: true

require_relative '../lib/command_helpers'

module Commands
  module TfPlanSummary
    extend CommandHelpers

    class << self
      def init
        require 'optparse'
        require 'json'
        require_relative '../lib/ansi.rb'
        need_gem 'tty-prompt'
      end

      def run(args)
        options = {
          interactive: false,
          hierarchy: false
        }

        args = OptionParser.new do |opts|
          opts.on('-i') do |v|
            options[:interactive] = v
          end
          opts.on('-h') do |v|
            options[:hierarchy] = v
          end
        end.parse!(args)

        if options[:interactive]
          raise 'must specify plan file in interactive mode' if args[0].blank?
        end

        data = if args[0]
                 JSON.parse(`terraform show -json #{args[0].inspect}`)
               else
                 JSON.parse(STDIN.read)
        end

        parts = []

        data['resource_changes'].each do |v|
          next unless v['change']

          case v['change']['actions']
          when ['no-op']
            # do nothing
          when ['create']
            parts << {
              action: 'create',
              address: v['address'],
              deps: find_deps(data, v['address'])
            }
          when ['update']
            parts << {
              action: 'update',
              address: v['address'],
              deps: find_deps(data, v['address'])
            }
          when ['delete']
            parts << {
              action: 'delete',
              address: v['address'],
              deps: find_deps(data, v['address'])
            }
          when %w[delete create]
            parts << {
              action: 'replace',
              address: v['address'],
              deps: find_deps(data, v['address'])
            }
          when ['read']
            parts << {
              action: 'read',
              address: v['address'],
              deps: find_deps(data, v['address'])
            }
          else
            puts "[??] #{v['address']}"
            puts "UNKNOWN ACTIONS: #{v['change']['actions'].inspect}"
            puts 'TODO: update plan_summary to support this!'
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
        end
      end

      def print_flat(parts)
        parts.each do |part|
          puts "[#{format_action(part[:action])}] #{format_address(part[:address])}"
        end
      end

      def run_interactive(parts, plan_name)
        prompt = TTY::Prompt.new
        result = prompt.multi_select('Update resources:', per_page: 99, echo: false) do |menu|
          parts.each do |part|
            label = "[#{format_action(part[:action])}] #{format_address(part[:address])}"
            menu.choice label, part[:address]
          end
        end

        if !result.empty?
          puts 'Re-running apply with the selected resources ...'
          system "terraform apply #{result.map { |a| "-target=#{a.inspect}" }.join(' ')}"
        else
          raise 'nothing selected'
        end
      end

      def print_nested(parts)
        parts = parts.deep_dup
        until parts.empty?
          part = parts.shift
          if part[:deps] == []
            if part[:met_deps] && part[:met_deps].length > 0
              indent = "  "
            else
              indent = ""
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
        if parent_address.empty?
          module_info = module_root[module_name]
        else
          module_info = module_root[module_name]["module"]
        end

        if m = address.match(/^module\.([^.]+)\./)
          find_config(module_info['module_calls'], m[1], m.post_match, parent_address + ["module.#{m[1]}"])
        else
          resource = module_info['resources'].find do |resource|
            address == resource['address']
          end if module_info['resources']
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

        resource = data['prior_state']['values']['root_module']['resources'].find do |resource|
          address == resource['address'] && index == resource['index']
        end if data['prior_state']['values']['root_module']['resources']

        if resource && resource["depends_on"]
          result += resource["depends_on"]
        end

        resource, parent_address = find_config(data['configuration'], 'root_module', address, [])
        if resource
          deps = []
          resource["expressions"].each do |k,v|
            if v.kind_of?(Hash) && v["references"]
              deps << v["references"]
            end
          end
          result += deps.map { |s| (parent_address + [s]).join(".") }
        end

        result
      end

      def format_action(action)
        case action
        when 'create'
          "#{ansi(:green)}+#{ansi(:reset)}"
        when 'update'
          "#{ansi(:yellow)}~#{ansi(:reset)}"
        when 'delete'
          "#{ansi(:red)}-#{ansi(:reset)}"
        when 'replace'
          "#{ansi(:red)}±#{ansi(:reset)}"
        when 'read'
          "#{ansi(:cyan)}>#{ansi(:reset)}"
        else
          action
        end
      end

      def format_address(address)
        parts = address.split('.')
        parts.each_with_index do |part, index|
          parts[index] = "#{ansi(:cyan)}#{part}#{ansi(:reset)}" if index.odd?
        end
        parts.join('.')
      end
    end
  end
end
