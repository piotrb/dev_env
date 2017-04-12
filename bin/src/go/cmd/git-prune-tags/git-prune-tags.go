package main

import (
	"flag"
	"fmt"
	"os"

	"../../lib/git"
)

var dryRun = flag.Bool("dry-run", false, "Dry Run")

func handleError(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func main() {
	flag.Parse()
	fmt.Printf("dryRun: %v\n", *dryRun)

	//remote := "origin"

	localTags, err := gitutil.AllTagNames()
	if err != nil {
		handleError(err)
	}
	fmt.Printf("%v\n", localTags)
	//remote_tags := []string{}
}

/*

remote_tag_details = `git ls-remote --tags #{remote}`.strip.split("\n")
remote_tag_details.each do |details|
  next if details == ""
  sha, tag = details.split("\t")
  next if tag =~ /\^\{\}$/
  remote_tags << tag.gsub(%r(^refs/tags/), "")
end

delete_tags = [] of String
local_tags.each do |local_tag|
  next if remote_tags.includes?(local_tag)
  puts "local tag '#{local_tag}' not found in '#{remote}'"
  delete_tags << local_tag
end

if delete_tags.empty?
  abort "No tags found locally which aren't on '#{remote}'"
end

if dry_run
  puts "#{delete_tags.size} tags would have been deleted, run without --dry-run to do the deed"
else
  response = prompt("Are you sure you want to delete these tags? (yn)")
  if response.downcase.strip =~ /^y/
    delete_tags.each do |local_tag|
      `git tag -d #{local_tag}`
    end

    puts "#{delete_tags.size} tags have been deleted"
  else
    puts "Aborted"
  end
end

*/
