package bundle

import (
	"../utils"
	"regexp"
	"strings"
)

type BundleItem struct {
	name    string
	version string
}

func BundleList() []BundleItem {
	var out = utils.Backtick("bundle", "list")
	var lines = strings.Split(out, "\n")

	var result = []BundleItem{}

	re := regexp.MustCompile("\\s+\\* (.+) \\((.+)\\)")

	for _, line := range lines {
		segs := re.FindStringSubmatch(line)
		if len(segs) > 0 {
			// fmt.Printf("%o", segs)
			result = append(result, BundleItem{segs[1], segs[2]})
		}
	}

	// fmt.Printf("%o", lines)

	return result
}

func BundleHas(gem_name string) bool {
	list := BundleList()
	for _, item := range list {
		if item.name == gem_name {
			return true
		}
	}
	return false
}
