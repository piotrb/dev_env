# frozen_string_literal: true

require_relative "../lib/env"

module Commands
  module MuxTf
    class << self
      def run(_args)
        Env.load(".env.mux")

        ignored = []

        ignored += ENV["MUX_IGNORE"].split(",") if ENV["MUX_IGNORE"]

        dirs = Dir["**/*/.terraform"].map { |n| n.gsub(%r{/\.terraform}, "") }
        tasks = dirs.map do |dir|
          {
            name: dir,
            cwd: dir,
            cmd: "tf-current",
          }
        end

        tasks.reject! { |t| t[:name].in?(ignored) }

        project = File.basename(Dir.getwd)

        if session_running?(project)
          puts "Killing existing session ..."
          tmux(%(kill-session -t "#{project}"))
        end

        # puts "Starting new session ..."
        tmux %(new-session -s "#{project}" -d)
        tmux %(select-pane -T "initial")

        tmux %(set-hook pane-exited "select-layout tiled")
        tmux %(set-hook window-pane-changed "select-layout tiled")

        tmux %(set mouse on)

        unless tasks.empty?
          tasks.each do |task|
            cwd_part = task[:cwd] ? "-c #{File.expand_path(task[:cwd]).inspect}" : nil
            cmd_part = task[:cmd] ? task[:cmd].inspect : nil
            tmux %(split-window #{cwd_part} -h -t "#{project}:1" #{cmd_part})
            tmux %(select-pane -T #{task[:name].inspect})
            tmux "select-layout tiled"
            task[:commands].each do |cmd|
              tmux %(send-keys #{cmd.inspect} Enter)
            end if task[:commands]
          end
        end

        initial_pane = find_pane("initial")
        tmux %(kill-pane -t #{initial_pane[:id].inspect})
        tmux "select-layout tiled"

        puts "\e]0;tmux: #{project}\007"

        extra = if ENV["MUXP_CC_MODE"]
                  "-CC"
                else
                  ""
                end

        tmux %(#{extra} attach -t "#{project}"), raise_on_error: false#, mode: :exec
      end

      private

      def find_pane(name)
        panes = `tmux list-panes -F "\#{pane_id},\#{pane_title}"`.strip.split("\n").map { |row| x = row.split(","); { id: x[0], name: x[1] } }
        panes.find { |pane| pane[:name] == name }
      end

      def session_running?(project)
        system("tmux has-session -t #{project.inspect} 2>/dev/null")
        $CHILD_STATUS.success?
      end

      def tmux_bin
        `which tmux`.strip
      end

      def tmux(cmd, raise_on_error: true, mode: :system)
        case mode
        when :system
          # puts " => tmux #{cmd}"
          system("tmux #{cmd}")
          unless $CHILD_STATUS.success?
            raise("`tmux #{cmd}' failed with code: #{$CHILD_STATUS.exitstatus}") if raise_on_error

            return false
          end
          true
        when :exec
          exec tmux_bin, *Shellwords.shellwords(cmd)
        end
      end
    end
  end
end
