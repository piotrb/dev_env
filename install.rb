#!env ruby
# vim: fdm=syntax fdl=0:
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

def flat_hash(hash, k = [])
  return {k => hash} unless hash.is_a?(Hash)
  hash.inject({}){ |h, v| h.merge! flat_hash(v[-1], k + [v[0]]) }
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
doLink "bin", "~"

git_config = {
  core: {
    excludesfile: File.expand_path("~/.gitignore")
  },
  push: {
    default: "current"
  }
}

flat_hash(git_config).each do |k,v|
  key = k.map(&:to_s).join(".")
  doRun "git config --global #{key} #{v.to_s.inspect}"
end

doRun "vim +BundleInstall +qall"
