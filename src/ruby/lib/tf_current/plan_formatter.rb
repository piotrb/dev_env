module TfCurrent
  class PlanFormatter
    import :run_with_each_line,
      :log,
      from: CommandHelpers, to_class: true

    class << self
      def pretty_plan(filename)
        pastel = Pastel.new

        plan_output = ""

        phase = :init

        parser = StatefulParser.new(normalizer: pastel.method(:strip))
        parser.state(:info, /^Acquiring state lock/)
        parser.state(:error, /Error locking state/, %i[none blank info])
        parser.state(:refreshing, /Refreshing Terraform state in-memory prior to plan.../, %i[none blank info])
        parser.state(:refresh_done, /^----------+$/, [:refreshing])
        parser.state(:plan_info, /Terraform will perform the following actions:/, [:refresh_done])
        parser.state(:plan_summary, /^Plan:/, [:plan_info])

        cmd = "terraform plan -out #{filename.inspect} -detailed-exitcode -compact-warnings -input=false"
        exit_status = run_with_each_line(cmd) { |raw_line|
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
        exit_status.exitstatus
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
