package main

import (
	"./golib/bundle"
	"./golib/utils"
	"fmt"
	"os"
)

func main() {
	has_bundle := utils.FileExists("Gemfile")
	is_compatible_app := (utils.FileExists("config/application.rb") || utils.FileExists("config/spring.rb")) && utils.FileExists(".spring")
	has_spring_in_bundle := bundle.BundleHas("spring")

	fmt.Printf("[bundle: %v | compatible: %v | spring_in_bundle: %v] ... ", has_bundle, is_compatible_app, has_spring_in_bundle)

	cmd_parts := os.Args[1:len(os.Args)]

	if len(cmd_parts) < 1 {
		fmt.Fprint(os.Stderr, "must specify command\n")
		os.Exit(1)
	}

	if is_compatible_app && ((has_bundle && has_spring_in_bundle) || !has_bundle) {
		fmt.Printf("Running via Spring\n")
		utils.Exec(append([]string{"bundle", "exec", "spring"}, cmd_parts...)...)
	} else if has_bundle {
		fmt.Printf("Running via Bundler\n")
		utils.Exec(append([]string{"bundle", "exec"}, cmd_parts...)...)
	} else {
		fmt.Printf("Running Directly\n")
		utils.Exec(cmd_parts...)
	}
}
