TARGET_DIRS=$(wildcard */)

.PHONY: build clean

build:
	for dir in $(TARGET_DIRS); do \
		${MAKE} -w -C $$dir -f ../common.mk build; \
	done

clean:
	for dir in $(TARGET_DIRS); do \
		${MAKE} -w -C $$dir -f ../common.mk clean; \
	done
