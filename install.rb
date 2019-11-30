#!env ruby
require "fileutils"
require "pathname"

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
    doRun("git clone --recursive #{repo.inspect} #{path.inspect}")
  end
end

def doGetHttp(url, path)
  path = File.expand_path(path)
  unless File.exist?(path)
    doRun("curl -LSso #{path.inspect} #{url.inspect}")
  end
end

def doShell(shell)
  unless ENV["SHELL"] == shell
    doRun "chsh -s #{shell}"
  end
end

def flat_hash(hash, k = [])
  return { k => hash } unless hash.is_a?(Hash)
  hash.inject({}) { |h, v| h.merge! flat_hash(v[-1], k + [v[0]]) }
end

doRun "git submodule init && git submodule sync && git submodule update"

doLink ".vimrc", "~"
doLink ".tmux.conf", "~"
doLink ".tmux.mac.conf", "~"
doLink ".bash_profile", "~"
doLink ".bashrc", "~"
doLink ".gitignore", "~"
doLink ".gvimrc.after", "~"
doLink ".profile.d", "~"
doLink ".powconfig", "~"
doLink ".gemrc", "~"
doLink ".tigrc", "~"
doLink "bin", "~"
doLink ".antigenrc", "~"

# Zsh Configs
doDir "~/.zsh"
doRun "curl -L git.io/antigen-nightly > ~/.zsh/antigen.zsh"

doLink ".zshrc", "~"

doShell "/bin/zsh"

# vim
doDir "~/.vim/bundle"
doClone "https://github.com/gmarik/Vundle.vim.git", "~/.vim/bundle/Vundle.vim"
doLink "vim/bundle.vim", "~/.vim", as: "bundle.vim"

# Git

doLink ".gitmessage", "~"

git_config = {
  gui: {
    gcwarning: false,
  },
  pull: {
    rebase: true,
    tags: true,
  },
  fetch: {
    prune: true,
    pruneTags: true,
    tags: true,
  },
  commit: {
    template: File.expand_path("~/.gitmessage"),
  },
  core: {
    mergeoptions: "--no-edit",
    excludesfile: File.expand_path("~/.gitignore"),
    pager: "less -FX",
  },
  push: {
    default: "current",
    followTags: true,
  },
  status: {
    showUntrackedFiles: "all",
  },
  diff: {
    compactionHeuristic: 1,
  },
  pager: {
    log: "diff-highlight | less -FX",
    show: "diff-highlight | less -FX",
    diff: "diff-highlight | less -FX",
  },
  alias: {
    lg: "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)%Creset' --abbrev-commit",
    pf: "push --force-with-lease",
  },
  rebase: {
    instructionFormat: "[%an] - %s",
  },
}

flat_hash(git_config).each do |k, v|
  key = k.map(&:to_s).join(".")
  doRun "git config --global #{key} #{v.to_s.inspect}"
end

doRun "vim -u /dev/null -N -c 'source ~/.vim/bundle.vim' +BundleInstall +qall"
