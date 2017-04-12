.SUFFIXES:
	MAKEFLAGS += -r

GO = go

CMD_NAME=$(notdir $(shell pwd))

.DEFAULT_GOAL := build

.PHONY: build clean deps remote_deps

LIBDIR=../../lib
DEPS=$(shell go list -f '{{ join .Imports "\n" }}' | grep "^_" | sed -e "s/^_//")
REMOTE_DEPS=$(shell go list -f '{{ join .Imports "\n" }}' | grep -v "^_" | grep "/")

TARGET=../.bin/${CMD_NAME}

GOBIN=$(abspath ../.bin)

remote_deps:
	[ "${REMOTE_DEPS}" ] && go get ${REMOTE_DEPS} || true

${TARGET}: ${CMD_NAME}.go ${DEPS} remote_deps
	export GOBIN=${GOBIN}; $(GO) install -ldflags -s .;

build: ${TARGET}

clean:
	rm -rf ${TARGET}