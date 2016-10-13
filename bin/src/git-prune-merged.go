package main

import (
	// "./golib/utils"
	"./golib/git"
	// "bufio"
	// "flag"
	"fmt"
	"os"
	// "regexp"
	// "strings"
	"github.com/libgit2/git2go"
)

func handleError(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}
}

func main() {

	// branches := []string{}
	// current_branch := ""

	// fmt.Printf("Getting all branches ...\n")

	repo, err := gitutil.DiscoverRepo(".")
	handleError(err)

	branches, err := gitutil.AllBranches(repo, git.BranchLocal)
	handleError(err)

	fmt.Printf("branches: %v\n", branches)

	current_branch, err := gitutil.CurrentBranchName(repo)
	handleError(err)

	fmt.Printf("current_branch: %v\n", current_branch)

	// if current_branch != "master" && current_branch != "develop" {
	// 	fmt.Fprintf(os.Stderr, "should be ran from master or develop\n")
	// 	os.Exit(1)
	// }

	for _, branch := range branches {
		if branch.Name == "develop" || branch.Name == "master" || branch.Name == current_branch {
			fmt.Printf("Skipping %v ...\n", branch.Name)
			continue
		}

		fmt.Printf("[%v] ...", branch.Name)

	}

}

// candidates = [] of String

// branches.each do |branch|
//   print "[#{branch}] ... "
//   begin
//     system "git clean -fq"
//     system "git merge --no-commit --no-ff #{branch.inspect} 2>/dev/null 1>/dev/null"
//     if $?.success?
//       changed = `git status --porcelain`.rstrip.split("\n").map { |s| s.rstrip }.reject { |s| s == "" }
//       if changed.empty?
//         puts "merged cleanly ..."
//         candidates << branch
//       else
//         puts "had some extra changes ..."
//       end
//     else
//       puts "merge failed"
//     end
//   ensure
//     if File.exists?(".git/MERGE_HEAD")
//       system "git merge --abort"
//     end
//     system "git clean -fq"
//   end
// end

// if candidates.empty?
//   puts "nothing to clean up"
// end

// candidates.each do |branch|
//   sh "git branch -D #{branch.inspect}"
// end
