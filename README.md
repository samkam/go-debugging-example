
Examples on different configurations for the delve debugger as a CLI tool, and through vs-code debugger

* learn how to launch with delve as a CLI tool
* learn how to uses tasks to automate setup
* launch debugger against a dockerized application
# prerequisites: 

* vscode downloaded
* Go vscode extension installed: https://marketplace.visualstudio.com/items?itemName=golang.go
* delve installed: `go get github.com/go-delve/delve/cmd/dlv`




# links of note
delve commands: 
https://github.com/go-delve/delve/blob/master/Documentation/cli/README.md
### fully understanding launch.json attributes: 
https://github.com/golang/vscode-go/blob/master/docs/debugging.md#launchjson-attributes
https://code.visualstudio.com/docs/editor/debugging#_launchjson-attributes

### fully understanding vscode tasks
https://code.visualstudio.com/docs/editor/tasks

### tidbits: 
what those pesky compiler flags are actually doing
https://golang.org/cmd/compile/ 

Alessandro Arzilli presentation: 
https://speakerdeck.com/aarzilli/internal-architecture-of-delve

### initial article that got me on this journey
https://medium.com/@kaperys/delve-into-docker-d6c92be2f823
(note: a bit out of date at the time of writing this README)


