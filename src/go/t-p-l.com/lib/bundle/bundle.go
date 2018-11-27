package bundle

import (
	"errors"
	"fmt"
	"regexp"
	"strings"

	"t-p-l.com/lib/utils"
)

type BundleItem struct {
	name    string
	version string
}

func BundleListE() ([]BundleItem, error) {
	var result = []BundleItem{}
	var out, err = utils.BacktickE("bundle", "list")
	if err != nil {
		return nil, errors.New(fmt.Sprintf("Failed getting bundle list: %s %s\n", out, err))
	}
	var lines = strings.Split(out, "\n")

	re := regexp.MustCompile("\\s+\\* (.+) \\((.+)\\)")

	for _, line := range lines {
		segs := re.FindStringSubmatch(line)
		if len(segs) > 0 {
			// fmt.Printf("%o", segs)
			result = append(result, BundleItem{segs[1], segs[2]})
		}
	}

	// fmt.Printf("%o", lines)

	return result, nil
}

func BundleHasE(gem_name string) (bool, error) {
	list, err := BundleListE()
	if err != nil {
		return false, err
	}

	for _, item := range list {
		if item.name == gem_name {
			return true, nil
		}
	}
	return false, nil
}
