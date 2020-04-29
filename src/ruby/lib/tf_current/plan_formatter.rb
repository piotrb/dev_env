module TfCurrent
  class PlanFormatter
    class << self
      include CommandHelpers
      include TerraformHelpers

      def pretty_plan(filename)
        pastel = Pastel.new

        plan_output = ""

        phase = :init

        meta = {}

        parser = StatefulParser.new(normalizer: pastel.method(:strip))
        parser.state(:info, /^Acquiring state lock/)
        parser.state(:error, /Error locking state/, %i[none blank info])
        parser.state(:refreshing, /Refreshing Terraform state in-memory prior to plan.../, %i[none blank info])
        parser.state(:refresh_done, /^----------+$/, [:refreshing])
        parser.state(:plan_info, /Terraform will perform the following actions:/, [:refresh_done])
        parser.state(:plan_summary, /^Plan:/, [:plan_info])

        parser.state(:error_lock_info, /Lock Info/, [:error])
        parser.state(:error, /^$/, [:error_lock_info])

        parser.state(:plan_error, /^Error: /, [:refreshing])

        status = tf_plan(out: filename, detailed_exitcode: true, compact_warnings: true) { |raw_line|
          plan_output << raw_line
          parser.parse(raw_line.rstrip) do |state, line|
            case state
            when :none
              if line.blank?
                # nothing
              else
                p [state, line]
              end
            when :info
              if /Acquiring state lock. This may take a few moments.../.match?(line)
                log "Acquiring state lock ...", depth: 2
              else
                p [state, line]
              end
            when :error
              meta["error"] = "lock"
              log Paint[line, :red], depth: 2
            when :plan_error
              if phase != :plan_error
                puts
                phase = :plan_error
              end
              meta["error"] = "refresh"
              log Paint[line, :red], depth: 2
            when :error_lock_info
              if line =~ /^  ([^ ]+):\s+([^ ].+)$/
                meta[$~[1]] = $~[2]
              end
              log Paint[line, :red], depth: 2
            when :refreshing
              if phase != :refreshing
                phase = :refreshing
                log "Refreshing state ", depth: 2, newline: false
              else
                print "."
              end
            when :refresh_done
              if phase != :refresh_done
                phase = :refresh_done
                puts
              else
                # nothing
              end
            when :plan_info
              log line, depth: 2
            when :plan_summary
              log line, depth: 2
            else
              p [state, line]
            end
          end
        }
        [status.status, meta]
      end

      def process_upgrade
        pastel = Pastel.new

        plan_output = ""

        phase = :init

        meta = {}

        parser = StatefulParser.new(normalizer: pastel.method(:strip))

        parser.state(:modules, /^Upgrading modules\.\.\./)
        parser.state(:backend, /^Initializing the backend\.\.\./, [:modules])
        parser.state(:plugins, /^Initializing provider plugins\.\.\./, [:backend])

        parser.state(:plugin_warnings, /^$/, [:plugins])

        status = tf_init(upgrade: true, color: false) { |raw_line|
          plan_output << raw_line
          parser.parse(raw_line.rstrip) do |state, line|
            case state
            when :modules
              if phase != state
                # first line
                phase = state
                log "Upgrding modules ", depth: 1, newline: false
                next
              end
              case line
              when /^- (?<module>[^ ]+) in (?<path>.+)$/
                # info = $~.named_captures
                # log "- #{info["module"]}", depth: 2
                print "."
              when /^Downloading (?<repo>[^ ]+) (?<version>[^ ]+) for (?<module>[^ ]+)\.\.\./
                # info = $~.named_captures
                # log "Downloading #{info["module"]} from #{info["repo"]} @ #{info["version"]}"
                print "D"
              when ""
                puts
              else
                p [state, line]
              end
            when :backend
              if phase != state
                # first line
                phase = state
                log "Initializing the backend ", depth: 1, newline: false
                next
              end
              case line
              when ""
                puts
              else
                p [state, line]
              end
            when :plugins
              if phase != state
                # first line
                phase = state
                log "Initializing provider plugins ...", depth: 1
                next
              end
              case line
              when /^- Downloading plugin for provider "(?<provider>[^\"]+)" \((?<provider_path>[^\)]+)\) (?<version>.+)\.\.\.$/
                info = $~.named_captures
                log "- #{info["provider"]} #{info["version"]}", depth: 2
              when "- Checking for available provider plugins..."
                # noop
              else
                p [state, line]
              end
            when :plugin_warnings
              if phase != state
                # first line
                phase = state
                next
              end

              log Paint[line, :yellow], depth: 1
            else
              p [state, line]
            end
          end
        }

        [status.status, meta]
      end

      def process_validation(info)
        remedies = Set.new

        if info["error_count"] > 0 || info["warning_count"] > 0
          log "Encountered #{Paint[info["error_count"], :red]} Errors and #{Paint[info["warning_count"], :yellow]} Warnings!", depth: 2
          info["diagnostics"].each do |dinfo|
            color = dinfo["severity"] == "error" ? :red : :yellow
            log "#{Paint[dinfo["severity"].capitalize, color]}: #{dinfo["summary"]}", depth: 3
            if dinfo["detail"]&.include?("terraform init")
              remedies << :init
            else
              log dinfo["detail"], depth: 4 if dinfo["detail"]
              log format_validation_range(dinfo["range"], color), depth: 4 if dinfo["range"]

              remedies << :unknown if dinfo["severity"] == "error"
            end
          end
        end

        remedies
      end

      private

      def format_validation_range(range, color)
        # filename: "../../../modules/pods/jane_pod/main.tf"
        # start:
        #   line: 151
        #   column: 27
        #   byte: 6632
        # end:
        #   line: 151
        #   column: 53
        #   byte: 6658

        context_lines = 3

        lines = range["start"]["line"]..range["end"]["line"]
        columns = range["start"]["column"]..range["end"]["column"]

        # on ../../../modules/pods/jane_pod/main.tf line 151, in module "jane":
        # 151:   jane_resources_preset = var.jane_resources_presetx
        output = []
        lines_info = lines.size == 1 ? "#{lines.first}:#{columns.first}" : "#{lines.first}:#{columns.first} to #{lines.last}:#{columns.last}"
        output << "on: #{range["filename"]} line#{lines.size > 1 ? "s" : ""}: #{lines_info}"

        if File.exist?(range["filename"])
          file_lines = File.read(range["filename"]).split("\n")
          extract_range = ([lines.first - context_lines, 0].max)..([lines.last + context_lines, file_lines.length - 1].min)
          file_lines.each_with_index do |line, index|
            if extract_range.cover?(index + 1)
              if lines.cover?(index + 1)
                start_col = 1
                end_col = :max
                if index + 1 == lines.first
                  start_col = columns.first
                elsif index + 1 == lines.last
                  start_col = columns.last
                end
                painted_line = paint_line(line, color, start_col: start_col, end_col: end_col)
                output << "#{Paint[">", color]} #{index + 1}: #{painted_line}"
              else
                output << "  #{index + 1}: #{line}"
              end
            end
          end
        end

        output
      end

      def paint_line(line, *paint_options, start_col: 1, end_col: :max)
        end_col = line.length if end_col == :max
        prefix = line[0, start_col - 1]
        suffix = line[end_col..-1]
        middle = line[start_col - 1..end_col - 1]
        "#{prefix}#{Paint[middle, *paint_options]}#{suffix}"
      end
    end
  end
end
