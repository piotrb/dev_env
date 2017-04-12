package main

import (
	"fmt"
	"os"

	"../../lib/utils"
)

func main() {
	hasBundle := utils.FileExists("Gemfile")

	fmt.Printf("[bundle: %v] ... ", hasBundle)

	cmdParts := os.Args[1:len(os.Args)]

	if len(cmdParts) < 1 {
		fmt.Fprint(os.Stderr, "must specify command\n")
		os.Exit(1)
	}

	if hasBundle {
		fmt.Printf("Running via Bundler\n")
		utils.Backtick("bundle", "check")
		utils.Exec(append([]string{"bundle", "exec"}, cmdParts...)...)
	} else {
		fmt.Printf("Running Directly\n")
		utils.Exec(cmdParts...)
	}
}
