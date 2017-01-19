#!env ruby
require 'fileutils'
require 'pathname'

def doLink(fn, dst, options = {})
  options = {
    :as => fn,
  }.merge(options)
  dst = File.expand_path(dst)
  src = File.expand_path(fn)
  full_dst = "#{dst}/#{options[:as]}"
  if File.exist?(full_dst)
    if File.symlink?(full_dst)
      unless File.readlink(full_dst) == src
        File.unlink(full_dst)
      end
    else
      File.unlink(full_dst)
    end
  end
  unless File.exist?(full_dst)
    FileUtils.ln_s(src, full_dst)
    puts "ln: #{src} -> #{full_dst}"
  end
end

def doRun(cmd)
  puts "$: #{cmd}"
  system(cmd) || raise("command failed with status: #{$?.exitstatus}")
end

def doDir(path)
  path = File.expand_path(path)
  unless File.exist?(path)
    puts "mkdir: #{path}"
    FileUtils.mkdir_p(path)
  end
end

def doClone(repo, path)
  path = File.expand_path(path)
  unless File.exist?(path)
    doRun("git clone #{repo.inspect} #{path.inspect}")
  end
end

def doGetHttp(url, path)
  path = File.expand_path(path)
  unless File.exist?(path)
    doRun("curl -LSso #{path.inspect} #{url.inspect}")
  end
end

def flat_hash(hash, k = [])
  return {k => hash} unless hash.is_a?(Hash)
  hash.inject({}){ |h, v| h.merge! flat_hash(v[-1], k + [v[0]]) }
end

doRun "git submodule init && git submodule sync && git submodule update"

doClone "git://github.com/robbyrussell/oh-my-zsh.git", "~/.oh-my-zsh"

doLink ".vimrc", "~"
doLink ".zshrc", "~"
doLink ".tmux.conf", "~"
doLink ".bash_profile", "~"
doLink ".bashrc", "~"
doLink ".gitignore", "~"
doLink ".gvimrc.after", "~"
doLink ".profile.d", "~"
doLink ".profilerc.d", "~"
doLink ".powconfig", "~"
doLink ".gemrc", "~"
doLink ".tigrc", "~"
doLink "bin", "~"
doDir "~/.config"

# vim
doDir "~/.vim/bundle"
doClone 'https://github.com/gmarik/Vundle.vim.git', '~/.vim/bundle/Vundle.vim'
doLink "vim/bundle.vim", "~/.vim", as: 'bundle.vim'

powerline_lib = "~/.local/lib/python2.7/site-packages/powerline/"
unless File.exist?(File.expand_path(powerline_lib))
  doRun "pip install powerline-status --user --upgrade"
end

# powerline
doLink "config/powerline", "~", :as => ".config/powerline"

git_config = {
  gui: {
    gcwarning: false,
  },
  pull: {
    rebase: true,
  },
  fetch: {
    prune: true,
  },
  core: {
    mergeoptions: '--no-edit',
    excludesfile: File.expand_path("~/.gitignore"),
  },
  push: {
    default: "current",
  },
  status: {
    showUntrackedFiles: "all",
  },
  diff: {
    compactionHeuristic: 1,
  },
  pager: {
    log: 'diff-highlight | less',
    show: 'diff-highlight | less',
    diff: 'diff-highlight | less',
  },
  alias: {
    #ct: "status",
    #ci: "commit",
    #br: "branch",
    #co: "checkout",
    #df: "diff",
    #lp: "log -p",
    #cp: "cherry-pick",
    lg: "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)%Creset' --abbrev-commit",
    pf: "push --force-with-lease",
  },
}

flat_hash(git_config).each do |k,v|
  key = k.map(&:to_s).join(".")
  doRun "git config --global #{key} #{v.to_s.inspect}"
end

doRun "vim -u /dev/null -N -c 'source ~/.vim/bundle.vim' +BundleInstall +qall"
