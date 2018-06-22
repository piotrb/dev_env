package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"regexp"
	"strings"

	"t-p-l.com/lib/utils"
)

var feature = flag.Bool("f", false, "Create as a Feature branch")
var epic = flag.Bool("e", false, "Create as an Epic branch")
var hotfix = flag.Bool("h", false, "Create as a Hotfix branch")
var techdebt = flag.Bool("t", false, "Create as a Tech Debt branch")
var sub = flag.Bool("s", false, "Create as a Sub branch")
var jira = flag.String("j", "", "Tag with Jira ticket/s")

func main() {
	flag.Parse()

	// fmt.Printf("feature: %v\n", *feature)
	// fmt.Printf("epic: %v\n", *epic)
	// fmt.Printf("hotfix: %v\n", *hotfix)
	// fmt.Printf("sub: %v\n", *sub)

	var name = ""

	if flag.NArg() == 0 {
		reader := bufio.NewReader(os.Stdin)
		fmt.Print("Name: ")
		name, _ = reader.ReadString('\n')
	} else {
		name = strings.Join(flag.Args(), " ")
	}

	invalidCharacters := regexp.MustCompile(`[^a-z0-9]`)
	multipleSpaces := regexp.MustCompile(` +`)

	name = strings.ToLower(name)
	name = invalidCharacters.ReplaceAllString(name, " ")
	name = multipleSpaces.ReplaceAllString(name, " ")
	name = strings.TrimSpace(name)
	name = strings.Replace(name, " ", "-", -1)

	if *sub {
		var currentBranch = strings.TrimSpace(utils.Backtick("git", "rev-parse", "--symbolic-full-name", "--abbrev-ref", "HEAD"))
		var pieces = strings.Split(currentBranch, "/")
		currentBranch = pieces[len(pieces)-1]
		name = fmt.Sprintf("%s-%s", currentBranch, name)
	}

	if *feature {
		name = fmt.Sprintf("feature/%s", name)
	}

	if *epic {
		name = fmt.Sprintf("epic/%s", name)
	}

	if *hotfix {
		name = fmt.Sprintf("hotfix/%s", name)
	}

	if *techdebt {
		name = fmt.Sprintf("tech-debt/%s", name)
	}

	if *jira != "" {
		name = fmt.Sprintf("%s-%s", *jira, name)
	}

	fmt.Printf("name: %v\n", name)

	utils.Run("git", "checkout", "-b", name)
	utils.Run("git", "config", fmt.Sprintf("branch.%s.remote", name), "origin")
	utils.Run("git", "config", fmt.Sprintf("branch.%s.merge", name), fmt.Sprintf("refs/heads/%s", name))
}
