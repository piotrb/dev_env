package gitutil

import (
	"errors"
	"strings"

	"gopkg.in/libgit2/git2go.v27"
	"t-p-l.com/lib/utils"
)

type BranchInfo struct {
	Name   string
	IsHead bool
	Ref    *git.Reference
}

func DiscoverRepo(path string) (*git.Repository, error) {
	dir, err := git.Discover(".", true, []string{})
	if err != nil {
		return nil, err
	}

	repo, err := git.OpenRepository(dir)
	if err != nil {
		return nil, err
	}

	return repo, nil
}

func AllBranches(repo *git.Repository, flags git.BranchType) ([]BranchInfo, error) {
	iter, err := repo.NewBranchIterator(flags)
	if err != nil {
		return nil, err
	}

	branches := []BranchInfo{}

	iterer := func(branch *git.Branch, branchType git.BranchType) error {
		name, err := branch.Name()
		if err != nil {
			return err
		}

		isHead, err := branch.IsHead()
		if err != nil {
			return err
		}

		info := BranchInfo{Name: name, IsHead: isHead, Ref: branch.Reference}

		branches = append(branches, info)
		return nil
	}

	iter.ForEach(iterer)

	return branches, nil
}

func CurrentBranch(repo *git.Repository) (*BranchInfo, error) {
	branches, err := AllBranches(repo, git.BranchLocal)
	if err != nil {
		return nil, err
	}

	for _, branch := range branches {
		if branch.IsHead {
			return &branch, nil
		}
	}

	return nil, errors.New("not on a branch")
}

func CurrentBranchName(repo *git.Repository) (string, error) {
	branch, err := CurrentBranch(repo)
	if err != nil {
		return "<error>", err
	} else {
		return branch.Name, nil
	}
}

func AllTagNames() ([]string, error) {
	output, err := utils.BacktickE("git", "tag")
	if err != nil {
		return nil, err
	}

	output = strings.TrimSpace(output)
	lines := strings.Split(output, "\n")
	return lines, nil
}
