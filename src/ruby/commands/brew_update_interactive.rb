module Commands
  module BrewUpdateInteractive
    extend CommandHelpers

    class << self
      def run(argv)
        prompt = TTY::Prompt.new

        list = JSON.parse(`brew outdated --json`)

        result = prompt.multi_select("Update packages?", per_page: 99) { |menu|
          list.each do |item|
            label = [
              "#{item["name"]} (#{item["installed_versions"].join(", ")} -> #{item["current_version"]})",
              item["pinned"] ? "[pinned: #{item["pinned_version"]}]" : nil,
            ].compact.join(" ")

            menu.choice label, item["name"], disabled: item["pinned"]
          end
        }

        if result.length > 0
          system "brew upgrade #{result.join(" ")}"
        else
          puts "nothing selected!"
        end
      rescue TTY::Reader::InputInterrupt
        puts "Aborted!"
      end

      def init
        need_gem "tty-prompt"
      end
    end
  end
end
