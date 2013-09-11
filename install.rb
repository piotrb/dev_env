#!env ruby
require 'fileutils'
require 'pathname'

def doLink(fn, dst)
  dst = File.expand_path(dst)
  src = File.expand_path(fn)
  full_dst = "#{dst}/#{fn}"
  unless File.exist?(full_dst)
    FileUtils.ln_s(src, full_dst)
    puts "ln: #{src} -> #{full_dst}"
  end
end

doLink(".vimrc.before", "~")
doLink(".vimrc.after", "~")
doLink(".zshrc", "~")
doLink(".tmux.conf", "~")
