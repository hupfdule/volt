
NAME := volt
SRC := $(shell find . -type d -name 'vendor' -prune -o -type f -name '*.go' -print)
VERSION := $(shell sed -n -E 's/var voltVersion = "([^"]+)"/\1/p' subcmd/version.go)
RELEASE_LDFLAGS := -s -w -extldflags '-static'
RELEASE_OS := linux windows darwin
RELEASE_ARCH := amd64 386

DEFAULT_ARCHS := linux/amd64 linux/386 windows/amd64 windows/386 darwin/amd64 darwin/386 linux/arm linux/arm64
ALL_ARCHS := $(shell go tool dist list)
os_and_arch = $(subst /, ,$@)
os = $(word 1, $(os_and_arch))
arch = $(word 2, $(os_and_arch))
exe = $(DIST_DIR)/$(NAME)-$(VERSION)-$(os)-$(arch)

DIST_DIR := dist
BIN_DIR := bin

all: $(BIN_DIR)/$(NAME)

$(BIN_DIR)/$(NAME): $(SRC)
	go build -o $(BIN_DIR)/$(NAME)

precompile:
	go build -a -i -o $(BIN_DIR)/$(NAME)
	rm $(BIN_DIR)/$(NAME)

clean:
	rm -f $(BIN_DIR)/$(NAME)
	rm -f -d $(BIN_DIR)
	rm -f $(DIST_DIR)/*
	rm -f -d $(DIST_DIR)

test:
	make
	go test -v -race -parallel 3 ./...

release: $(DEFAULT_ARCHS)

$(DEFAULT_ARCHS):
	@exe=$(exe); \
	if [ $(os) = windows ]; then \
	  exe=$$exe.exe; \
	fi; \
	echo "Creating "$$exe; \
	GOOS=$(os) GOARCH=$(arch) go build -tags netgo -installsuffix netgo -ldflags "$(RELEASE_LDFLAGS)" -o $$exe

update-doc: all
	go run _scripts/update-cmdref.go >CMDREF.md

.PHONY: all clean precompile test release update-doc
