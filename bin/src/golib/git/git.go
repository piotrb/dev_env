package gitutil

import (
	// "fmt"
	"errors"
	"github.com/libgit2/git2go"
)

type BranchInfo struct {
	Name   string
	IsHead bool
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

		info := BranchInfo{Name: name, IsHead: isHead}

		branches = append(branches, info)
		return nil
	}

	iter.ForEach(iterer)

	return branches, nil
}

func CurrentBranchName(repo *git.Repository) (string, error) {
	branches, err := AllBranches(repo, git.BranchLocal)
	if err != nil {
		return "<error>", err
	}

	for _, branch := range branches {
		if branch.IsHead {
			return branch.Name, nil
		}
	}

	return "<na>", errors.New("not on a branch")
}
