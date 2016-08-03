#!/usr/bin/env ruby

def sh(cmd, raise_on_error=true)
  puts "# #{cmd}"
  r = system(cmd)
  raise "execution of `#{cmd}' failed: #{$?.exit_status}" unless r if raise_on_error
  r
end

branches = [] of String
current_branch = nil

puts "Getting all branches ..."
`git branch`.strip.split("\n").each do |line|
  line = line.strip
  if line =~ /^\*/
    line = line.gsub(/^\* /, "")
    current_branch = line
  end
  branches << line
end

raise "should be ran from master or develop" unless ["master", "develop"].includes?(current_branch) || ENV["FORCE"]

branches -= ["develop", "master", current_branch, "releases"]

candidates = [] of String

branches.each do |branch|
  print "[#{branch}] ... "
  begin
    system "git clean -fq"
    system "git merge --no-commit --no-ff #{branch.inspect} 2>/dev/null 1>/dev/null"
    if $?.success?
      changed = `git status --porcelain`.split("\n").map { |s| s.rstrip }
      if changed.empty?
        puts "merged cleanly ..."
        candidates << branch
      else
        puts "had some extra changes ..."
      end
    else
      puts "merge failed"
    end
  ensure
    if File.exists?(".git/MERGE_HEAD")
      system "git merge --abort"
    end
    system "git clean -fq"
  end
end

if candidates.empty?
  puts "nothing to clean up"
end

candidates.each do |branch|
  sh "git branch -D #{branch.inspect}"
end
