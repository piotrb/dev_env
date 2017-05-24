package main

import (
	"fmt"
	"os"

	"t-p-l.com/lib/bundle"
	"t-p-l.com/lib/utils"
)

func main() {
	hasBundle := utils.FileExists("Gemfile")
	isCompatibleApp := (utils.FileExists("config/application.rb") || utils.FileExists("config/spring.rb")) && utils.FileExists(".spring")
	var hasSpringInBundle = false
	if hasBundle {
		var err = error(nil)
		hasSpringInBundle, err = bundle.BundleHasE("spring")
		if err != nil {
			fmt.Printf("Failed Checking for Spring in Bundle:\n%s", err)
			os.Exit(1)
		}
	}

	fmt.Printf("[bundle: %v | compatible: %v | in_bundle: %v] ... ", hasBundle, isCompatibleApp, hasSpringInBundle)

	cmdParts := os.Args[1:len(os.Args)]

	if len(cmdParts) < 1 {
		fmt.Fprint(os.Stderr, "must specify command\n")
		os.Exit(1)
	}

	if isCompatibleApp && ((hasBundle && hasSpringInBundle) || !hasBundle) {
		fmt.Printf("Running via Spring\n")
		utils.Backtick("bundle", "check")
		utils.Exec(append([]string{"bundle", "exec", "spring"}, cmdParts...)...)
	} else if hasBundle {
		fmt.Printf("Running via Bundler\n")
		utils.Backtick("bundle", "check")
		utils.Exec(append([]string{"bundle", "exec"}, cmdParts...)...)
	} else {
		fmt.Printf("Running Directly\n")
		utils.Exec(cmdParts...)
	}
}
