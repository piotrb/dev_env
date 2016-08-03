CRYSTAL = crystal

.DEFAULT_GOAL := build

TARGETS = ../git-branchify ../git-prune-merged ../git-prune-tags ../spring_wrapper

../git-branchify: git-branchify.cr
	$(CRYSTAL) build --release "$<" -o "$@"

../git-prune-merged: git-prune-merged.cr
	$(CRYSTAL) build --release "$<" -o "$@"

../git-prune-tags: git-prune-tags.cr
	$(CRYSTAL) build --release "$<" -o "$@"

../spring_wrapper: spring_wrapper.cr
	$(CRYSTAL) build --release "$<" -o "$@"

.PHONY: build clean

build: $(TARGETS)

clean:
	rm -vf $(TARGETS)

