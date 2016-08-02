
CRYSTAL = crystal

git-branchify: src/git-branchify.cr
	$(CRYSTAL) build --release "$<" -o "$@"

git-prune-merged: src/git-prune-merged.cr
	$(CRYSTAL) build --release "$<" -o "$@"

phony: build

build: git-branchify git-prune-merged


