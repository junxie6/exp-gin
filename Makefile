PID = ./app.pid
GO_FILES = $(wildcard *.go)

APP_NAME = exp-gin
ROOT_DIR = $(CURDIR)
BIN_DIR = $(ROOT_DIR)/bin
APP = $(BIN_DIR)/$(APP_NAME)
LOG_DIR = $(ROOT_DIR)/log
LOG_FILE = $(LOG_DIR)/$(APP_NAME).log
LOG_CONFIG = $(ROOT_DIR)/logrotate.conf
LOG_STATUS = $(LOG_DIR)/status

# check we have a couple of dependencies
dependencies:
	@command -v bin/reflex >/dev/null 2>&1 || { printf >&2 "bin/reflex is not installed, please run: make reflex\n"; exit 1; }

# default targets to run when only running `make`
default: dependencies test

# TODO: why 2>/dev/null ??
kill:
	echo "@@@@@ Doing kill"
	kill `cat $(PID)` 2>/dev/null || true

# run formatting tool and build
go-build: dependencies go-clean
	go mod vendor
	go build -v -x -mod vendor -o $(APP)

NotYetbuild2: $(GO_FILES)
	go build -o $(APP)

# start
NotYetstart:
	echo "@@@@@ Doing start"
	rm -f $(PID)
	$(APP) 2>&1 & echo $$! > $(PID)

start: go-build
	mkdir -p $(BIN_DIR)
	mkdir -p $(LOG_DIR)
	logrotate -v --state $(LOG_STATUS) $(LOG_CONFIG)
	$(APP) 2>&1 | tee --append $(LOG_FILE)

#sh -c "$(APP) & echo $$! > $(PID)"

# restart
restart: kill go-build start

# clean up
go-clean:
	@echo 'make go-clean not implemented yet'

go-clean2:
	go clean -i -x -modcache

test:
	echo 'make test not implemented yet'

# reflex
reflex:
	mkdir -p $(BIN_DIR)
	git clone https://github.com/cespare/reflex.git --depth 1
	cd $(ROOT_DIR)/reflex
	go mod vendor
	go build -v -x -mod vendor -o $(BIN_DIR)/reflex
	cd $(ROOT_DIR)
	rm -rf $(ROOT_DIR)/reflex

# targets not associated with files
# let's go to reserve rules names
.PHONY: start run restart kill reflex 

run:
	bin/reflex --start-service -d none -r '\.go$$' -R '^vendor/' -R '^node_modules/' -- make start

