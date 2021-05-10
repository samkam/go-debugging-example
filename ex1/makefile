'/install: 

debug_local:
	dlv debug --help | head -13
	dlv debug main.go --init=init.sh -- arbitrary_argument
build_debuggable_executable:
	# build without compiler optimizations
	go build -gcflags="all=-N -l" -o debuggable_executable main.go
test: 
	go test ./...
debug_exec:
	dlv exec --help | head -13
	ENVIRONMENTAL_VARIABLE=set dlv exec debuggable_executable -- arbitrary_argument
run:
	ENVIRONMENTAL_VARIABLE=set ./debuggable_executable arbitrary_argument
kill: 
	# "-f" searches for matching expression, "-l" list PID
	pkill -f -l debuggable_executable
debug_attach:
	dlv attach --help | head -12
	pgrep debuggable_executable
	dlv attach $(shell pgrep debuggable_executable)
debug_test: 
	dlv test --help | head -12
	dlv test some_package
docker_build:
	docker build -t debug-example-app . 
docker_debug:
	docker run --rm --publish 40000:40000 --publish 8080:8080 --security-opt=seccomp:unconfined --name debug-example debug-example-app
