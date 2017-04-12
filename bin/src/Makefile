.SUFFIXES:
	MAKEFLAGS += -r

.DEFAULT_GOAL := build

.PHONY: build clean go install_go

go:
	${MAKE} -w -C go build

install_go:
	ln -sfv go/cmd/.bin/* ..

build: go install_go

clean:
	${MAKE} -w -C go clean
