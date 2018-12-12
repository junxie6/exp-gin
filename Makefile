SHELL = /bin/bash

PID = ./app.pid
GO_FILES = $(wildcard *.go)

APP_NAME = exp-gin

ROOT_DIR = $(CURDIR)
BIN_DIR = $(ROOT_DIR)/bin
APP = $(BIN_DIR)/$(APP_NAME)

LOG_DIR = $(ROOT_DIR)/log
LOG_FILE = $(LOG_DIR)/$(APP_NAME).log
LOG_FILE_BUILD = $(LOG_DIR)/build-$(APP_NAME).log
LOG_CONFIG = $(ROOT_DIR)/logrotate.conf
LOG_STATUS = $(LOG_DIR)/status

REFLEX = $(BIN_DIR)/reflex
REFLEX_DIR = $(ROOT_DIR)/reflex

# check we have a couple of dependencies
dependencies:
	@cd $(ROOT_DIR) && command -v $(REFLEX) >/dev/null 2>&1 || { printf >&2 $(REFLEX)" is not installed, please run: make reflex\n"; exit 1; }
	cd $(ROOT_DIR) && mkdir -p $(BIN_DIR)
	cd $(ROOT_DIR) && mkdir -p $(LOG_DIR)

# default targets to run when only running `make`
default: dependencies

# TODO: why 2>/dev/null ??
kill:
	echo "@@@@@ Doing kill"
	kill `cat $(PID)` 2>/dev/null || true

# run formatting tool and build
go-build: dependencies
	cd $(ROOT_DIR) && logrotate -v --state $(LOG_STATUS) $(LOG_CONFIG)
	set -o pipefail; cd $(ROOT_DIR) && go mod vendor -v 2>&1 | tee --append $(LOG_FILE_BUILD)
	set -o pipefail; cd $(ROOT_DIR) && go build -o $(APP) -v -x -mod vendor 2>&1 | tee --append $(LOG_FILE_BUILD)

go-run:
	cd $(ROOT_DIR) && go run -v -mod vendor -race main.go

# NOTE: -count 1 to disable go test cache
go-test:
	cd $(ROOT_DIR) && go test -v -count 1 -mod vendor -race $(APP_NAME)/...

go-test-cover:
	cd $(ROOT_DIR) && go test -v -count 1 -cover -mod vendor $(APP_NAME)/...

go-tidy:
	cd $(ROOT_DIR) && go mod tidy -v

go-clean:
	cd $(ROOT_DIR) && go clean -i -x -modcache

# start
NotYetstart:
	echo "@@@@@ Doing start"
	rm -f $(PID)
	$(APP) 2>&1 & echo $$! > $(PID)

start: go-build
	cd $(ROOT_DIR) && logrotate -v --state $(LOG_STATUS) $(LOG_CONFIG)
	set -o pipefail; cd $(ROOT_DIR) && $(APP) 2>&1 | tee --append $(LOG_FILE)

# reflex
reflex:
	cd $(REFLEX_DIR) && mkdir -p $(BIN_DIR)
	cd $(REFLEX_DIR) && git clone https://github.com/cespare/reflex.git --depth 1
	cd $(REFLEX_DIR) && go mod vendor -v
	cd $(REFLEX_DIR) && go build -o $(REFLEX) -v -x -mod vendor
	rm -rf $(REFLEX_DIR)

run:
	cd $(ROOT_DIR) && bin/reflex --start-service -d none -r '\.go$$' -R '^vendor/' -R '^node_modules/' -- make start

# targets not associated with files
# let's go to reserve rules names
.PHONY: start run kill reflex go-build
