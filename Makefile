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
default: dependencies test

# TODO: why 2>/dev/null ??
kill:
	echo "@@@@@ Doing kill"
	kill `cat $(PID)` 2>/dev/null || true

# run formatting tool and build
go-build: dependencies
	cd $(ROOT_DIR) && logrotate -v --state $(LOG_STATUS) $(LOG_CONFIG)
	set -o pipefail; cd $(ROOT_DIR) && go mod vendor 2>&1 | tee --append $(LOG_FILE_BUILD)
	set -o pipefail; cd $(ROOT_DIR) && go build -v -x -mod vendor -o $(APP) 2>&1 | tee --append $(LOG_FILE_BUILD)

go-test:
	cd $(ROOT_DIR) && go test -v -mod vendor $(APP_NAME)/...

go-test-cover:
	cd $(ROOT_DIR) && go test -v -cover -mod vendor $(APP_NAME)/...

go-tidy:
	cd $(ROOT_DIR) && go mod tidy

go-clean:
	go clean -i -x -modcache

NotYetbuild2: $(GO_FILES)
	go build -o $(APP)

# start
NotYetstart:
	echo "@@@@@ Doing start"
	rm -f $(PID)
	$(APP) 2>&1 & echo $$! > $(PID)

start: go-build
	cd $(ROOT_DIR) && logrotate -v --state $(LOG_STATUS) $(LOG_CONFIG)
	set -o pipefail; cd $(ROOT_DIR) && $(APP) 2>&1 | tee --append $(LOG_FILE)

#sh -c "$(APP) & echo $$! > $(PID)"

# restart
restart: kill go-build start

test:
	echo 'make test not implemented yet'

# reflex
reflex:
	mkdir -p $(BIN_DIR)
	git clone https://github.com/cespare/reflex.git --depth 1
	cd $(REFLEX_DIR) && go mod vendor
	cd $(REFLEX_DIR) && go build -v -x -mod vendor -o $(REFLEX)
	rm -rf $(REFLEX_DIR)

run:
	cd $(ROOT_DIR) && bin/reflex --start-service -d none -r '\.go$$' -R '^vendor/' -R '^node_modules/' -- make start

# targets not associated with files
# let's go to reserve rules names
.PHONY: start run restart kill reflex go-build
