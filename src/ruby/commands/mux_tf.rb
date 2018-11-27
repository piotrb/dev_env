require_relative '../lib/env'

module Commands
  module MuxTf
    class << self
      def run(args)
        Env.load(".env.mux")

        ignored = []

        if ENV['MUX_IGNORE']
          ignored += ENV['MUX_IGNORE'].split(",")
        end

        dirs  = Dir["**/*/.terraform"].map { |n| n.gsub(/\/\.terraform/, '') }
        tasks = dirs.map { |dir|
          {
            name:    dir,
            cwd:     dir,
            commands: [
              "terraform init",
              "exec terraform apply"
            ],
          }
        }

        tasks.reject! { |t| t[:name].in?(ignored) }

        project = File.basename(Dir.getwd)

        if session_running?(project)
          puts "Killing existing session ..."
          tmux(%{kill-session -t "#{project}"})
        end

        # puts "Starting new session ..."
        tmux %{new-session -s "#{project}" -d}
        # tmux %{send-keys "setpane shell" Enter}

        # tmux "set remain-on-exit on"

        # tmux %{set-window-option remain-on-exit on}
        tmux %{set mouse on}

        if tasks.length > 0
          task = tasks.pop

          tmux %{send-keys "setpane #{task[:name]}" Enter}
          tmux %{send-keys "cd #{task[:cwd].inspect}" Enter} if task[:cwd]
          task[:commands].each do |cmd|
            tmux %{send-keys #{cmd.inspect} Enter}
          end

          tmux "select-layout tiled"

          tasks.each do |task|
            tmux %{split-window -h -t "#{project}:1"}
            tmux %{send-keys "setpane #{task[:name]}" Enter}
            tmux %{send-keys "cd #{task[:cwd].inspect}" Enter} if task[:cwd]
            task[:commands].each do |cmd|
              tmux %{send-keys #{cmd.inspect} Enter}
            end
            tmux "select-layout tiled"
          end
        end

        puts "\e]0;tmux: #{project}\007"

        if ENV['MUXP_CC_MODE']
          extra = "-CC"
        else
          extra = ""
        end

        tmux %{#{extra} attach -t "#{project}"}#, mode: :exec
      end

      private

      def session_running?(project)
        system("tmux has-session -t #{project.inspect} 2>/dev/null")
        $?.success?
      end

      def tmux_bin
        `which tmux`.strip
      end

      def tmux(cmd, raise_on_error: true, mode: :system)
        case mode
        when :system
          system("tmux #{cmd}")
          unless $?.success?
            raise("failed") if raise_on_error
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
