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

def doRun(cmd)
  puts "$: #{cmd}"
  system(cmd) || raise("command failed with status: #{$?.exitstatus}")
end

doRun "git submodule init && git submodule sync && git submodule update"

doLink ".vimrc.before", "~"
doLink ".vimrc.after", "~"
doLink ".zshrc", "~"
doLink ".tmux.conf", "~"
doLink ".janus", "~"
doLink ".bash_profile", "~"
doLink ".bashrc", "~"
doLink ".gitignore", "~"
doLink ".gvimrc.after", "~"
doLink ".profile.d", "~"
doLink ".powconfig", "~"

doRun "git config --global core.excludesfile ${HOME}/.gitignore"
