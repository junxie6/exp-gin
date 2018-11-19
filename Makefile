PID      = ./app.pid
GO_FILES = $(wildcard *.go)
APP      = ./bin/exp-gin

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
	echo "@@@@@ Doing go-build"
	go mod vendor
	go build -v -x -mod vendor -o $(APP)

NotYetbuild2: $(GO_FILES)
	go build -o $(APP)

# start
start:
	echo "@@@@@ Doing start"
	rm -f $(PID)
	$(APP) 2>&1 & echo $$! > $(PID)

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
	mkdir -p bin
	git clone https://github.com/cespare/reflex.git --depth 1
	cd reflex
	go mod vendor
	go build -v -x -mod vendor -o ../bin/reflex
	cd ..
	rm -rf reflex

# targets not associated with files
# let's go to reserve rules names
.PHONY: start run restart kill reflex 

run: start
	echo "@@@@@ Doing run"
	bin/reflex --start-service -d none -r '\.go$$' -R '^vendor/' -- make restart || make kill

