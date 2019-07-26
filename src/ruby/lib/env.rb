module Env
  def self.load(file)
    if File.exist?(file)
      File.open(file) do |fh|
        fh.each_line do |line|
          unless line.strip.empty? || line.strip =~ /^#/
            k, v = line.rstrip.split("=", 2)
            ENV[k] = v
          end
        end
      end
    end
  end
end
