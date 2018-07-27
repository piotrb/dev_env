require 'yaml'
require 'open3'
require 'ansi'

module Commands
  module BisectTests
    class << self
      def run(_args)
        all_tests = File.read(config['all_tests_from']).split("\n").map(&:strip)
        failing   = config['failing']
        skip      = config['skip']
        passing   = all_tests - failing - skip

        setup_interrupt

        cmd_base = config['command']

        results = []

        failing.each do |failing_file|
          matching_batches = []

          with_docker_compose do

            puts "Processing failing file: #{failing_file} ..."

            puts "Running it on its own to be sure ..."
            if execute_batch(cmd_base, [], failing_file) == :bad
              result = "THE FILE ITSELF!"
            else
              puts "Running it as a whole batch ..."
              if execute_batch(cmd_base, passing, failing_file) == :bad
                result = in_bsearch_batches(passing, matching_batches: matching_batches) do |batch|
                  execute_batch(cmd_base, batch, failing_file)
                end
              else
                result = "NO FILES, the whole batch passes!"
              end
            end

            results << {
              failing_file:     failing_file,
              result:           result,
              matching_batches: matching_batches,
            }
          end
        end

        results.each do |result|
          render_result(result[:failing_file], result[:result], result[:matching_batches])
        end
      end

      private

      def config
        @config ||= YAML.load_file("bisect.yml")
      end

      def setup_interrupt
        @interrupt = false
        Signal.trap("INT") { @interrupt = true }
      end

      def split_batch(list)
        [list[0..(list.length / 2 - 1)], list[(list.length / 2)..-1]]
      end

      def run_part(side, level, part, &block)
        puts "[running #{side} set (level: #{level.join('.')}, items: #{part.length})]"
        result = block.call(part)
        puts "[#{side} result: #{result.inspect}]"
        result
      end

      def render_result(failing_file, result, matching_batches)
        puts
        puts "#" * 80
        puts "### RESULT FOR: #{failing_file}"
        puts "#" * 80

        if result
          puts
          puts "=" * 80
          puts " Result: #{result.inspect}"

          puts
          puts "=" * 80
          puts " Repro command:"
          puts "#{config['command']} #{failing_file.inspect} #{result.inspect}"
        else
          puts
          puts "=" * 80
          puts " Matching Batches:"

          matching_batches.each do |batch|
            puts "-" * 20
            batch.each do |line|
              puts "  #{line}"
            end
          end
        end
      end

      def in_bsearch_batches(list, level: [], matching_batches:, shuffled: false, &block)
        raise ArgumentError, "list should have more than 1 element" unless list.length > 1
        return nil if @interrupt
        part1, part2 = split_batch(list)

        result1 = run_part(:left, level + ['l'], part1, &block)
        result2 = run_part(:right, level + ['r'], part2, &block) if result1 == :good

        if result1 == :bad
          matching_batches << part1
          if part1.length == 1
            return part1.first
          else
            return in_bsearch_batches(part1, level: level + ['l'], matching_batches: matching_batches, &block)
          end
        end

        if result2 == :bad
          matching_batches << part2
          if part2.length == 1
            return part2.first
          else
            return in_bsearch_batches(part2, level: level + ['r'], matching_batches: matching_batches, &block)
          end
        end

        if result1 == :good && result2 == :good
          puts "*" * 80
          puts "* BOTH SIDES DID NOT MATCH!"
          puts "* SHUFFLING WHAT'S LEFT AND TRYING AGAIN" unless shuffled
          puts "*" * 80

          list = list.shuffle
          return in_bsearch_batches(list, level: level + ['SHUFFLE'], matching_batches: matching_batches, &block)
        end
      end

      def run_cmd(cmd)
        system cmd
        raise "failed: #{$?.exitstatus}" unless $?.success?
      end

      def with_docker_compose
        @batch_name = "#{File.basename(Dir.getwd)}-#{Process.pid}"
        run_cmd to_docker_cmd(config['init_cmd'])
        yield
      ensure
        run_cmd "docker-compose -p #{@batch_name.inspect} down -v"
      end

      def to_docker_cmd(cmd)
        "docker-compose -p #{@batch_name.inspect} run app #{cmd}"
      end

      def execute_batch(cmd_base, batch, failing_file)
        cmd = to_docker_cmd("#{cmd_base} #{(batch + [failing_file]).map(&:inspect).join(' ')}")
        puts ansi("[running batch with #{batch.length} additional files]", :cyan)
        File.open('batch_log.log', "w+") do |fh|
          Open3.popen2e(cmd) do |i, o, t|
            i.close
            to = Thread.new do
              until o.eof?
                fh.write o.read
                fh.flush
              end
            end
            to.join
            puts ansi("[batch exit: #{t.value}]", :yellow)
            t.value.success? ? :good : :bad
          end
        end
      end
    end
  end
end
