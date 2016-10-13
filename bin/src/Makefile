.SUFFIXES:
	MAKEFLAGS += -r

CRYSTAL = crystal
GO = go
GOLIB_DEPS = $(wildcard golib/**/*.go)

.DEFAULT_GOAL := build

GO_FILES = $(wildcard *.go)
GO_TARGETS = $(patsubst %.go,../%,$(GO_FILES))

CR_FILES = $(wildcard *.cr)
CR_TARGETS = $(patsubst %.cr,../%,$(CR_FILES))

TARGETS = $(CR_TARGETS) $(GO_TARGETS)

../% : %.go $(GOLIB_DEPS)
	$(GO) build -o "$@" "$<"

../% : %.cr
	$(CRYSTAL) build --release "$<" -o "$@"

.PHONY: build clean

build: $(TARGETS)

clean:
	rm -vf $(TARGETS)

