# execute with no debugger
build_debuggable_executable:
	# build without compiler optimizations
	go build -gcflags="all=-N -l" -o debuggable_executable main.go
run:
	ENVIRONMENTAL_VARIABLE=set ./debuggable_executable somevalue
open:
	open http://localhost:8080/ping
test: 
	go test ./...

# 1: delve debug locally
debug_local:
	dlv debug --help | head -13
	ENVIRONMENTAL_VARIABLE=set dlv debug main.go -- somevalue
# 2: delve debug test locally
debug_test: 
	dlv test --help | head -12
	dlv test ./some_package
# 3: locally running process
debug_attach:
	dlv attach --help | head -12
	pgrep debuggable_executable
	dlv attach $(shell pgrep debuggable_executable)

# 4: connecting to a remote server
# explanation of flags:
# --accept-multiclient               Allows a headless server to accept multiple client connections.
# --headless                         Run debug server only, in headless mode.
debug_server:
	ENVIRONMENTAL_VARIABLE=set dlv debug main.go --accept-multiclient --headless --listen localhost:40000 --api-version 2 -- somevalue
debug_connect:
	dlv connect localhost:40000
# 4: connect to docker container 

docker_build:
	docker build -t debug-example-app . 
# runs docker container unmodified
docker_run:
	docker run --rm --publish 40000:40000 --publish 8080:8080 --security-opt=seccomp:unconfined --name debug-example debug-example-app
# overwrites CMD with command to launch debugger
docker_debug:
	docker run --rm --expose=40000 --publish 40000:40000 --publish 8080:8080 --security-opt=seccomp:unconfined --name debug-example debug-example-app \
		dlv debug main.go --listen=:40000 --headless=true --api-version=2 -- somevalue

debug_with_script:
	ENVIRONMENTAL_VARIABLE=set dlv debug main.go  --init=scripts/debug_script.txt -- somevalue
# 5: unspecified commands
kill: 
	# "-f" searches for matching expression, "-l" list PID
	pkill -f -l debuggable_executable
# delve exec locally example
debug_exec:
	dlv exec --help | head -13
	ENVIRONMENTAL_VARIABLE=set dlv exec debuggable_executable -- arbitrary_argument

ex0: 
	ENVIRONMENTAL_VARIABLE=set dlv debug main.go --init scripts/debug_script.txt -- somevalue
debug_trace:
	ENVIRONMENTAL_VARIABLE=set dlv trace main.go "GetMessa.*"  -- somevalue 