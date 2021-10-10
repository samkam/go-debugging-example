# gophercon talk 
Before I present I want to show: 


1. Launching a debugger, setting a breakpoint, inspecting a nested struct, changing a value and then resuming execution in VS code

2. 

3. How to use the CLI delve tool, set breakpoint briefly. 

Why debugger are useful: 

Bad debugger code snippets: 


---
ACTUAL SCRIPT
This talk is for anyone that isn’t just for debugger enthusiasts, but also those that have wrestled with setting up a debugger for their project, and even the debugger skeptical. 

For all of you, my pitch is this: setting up a debugger requires understanding the nuances of how the debugger works and how to configure it in relation to your project. It can feel like a lot of work to set it up in the middle of hunting down a bug. But here’s the thing, it’s a time investment, but it’s a one time investment. Once you figure out the configuration needed for your project, You can continue to reuse that configuration and share it with your whole team, hell, even put it in the repo, and suddenly you can debug with a press of a button. 

Note: I’m assuming you have used a debugger of some kind in the past, and are familiar with the basic operations of setting breakpoints and stepping through code execution. Even if you aren’t, this is most intuitive part of a debugger. Again, we are focusing on the unintuitive part, the 

First, I’m gonna spend a little time proselytizing debuggers to the skeptical. Have you ever found yourself  doing this? Trying to print out a value?  And then you realize it’s the wrong value, so you print out the struct, and then it’s too much output, so you have to figure out which member structs you care about? And then it’s formatted weird so you have to look up string formatting parameters? 

Well, using a GUI debugger, like Delve via the Go-extension in VS Code, you see all the variables visible in the current scope, at any breakpoint. 
example 0:
```
dlv debug 
break main.go:25
continue
local
# ah, of course, we didn't set the environment variable 
exit
export ENVIRONMENTAL_VARIABLE="some value" 

go run main.go
# hrmm, still isn't working 
dlv debug main.go 
break main.go:28
continue 
stack
# okay, looks like it's an issue that we aren't passing in command line arguments
exit
go run main.go somevalue
# okay, looks like that was the issue.
ctrl+c
# but how do we invoke the bugger with a command line argument? 
# i'll save you some googling. the -- (dash dash) argument separates the delve arguments from arguments passed into the executable itself
dlv debug main.go -- somevalue 
continue 
# okay, seems to be working!  
```
but of course, we are going to have to remember the program argument, as well as setting the environment variable! we don't want to keep around 1 env variable for a single frame mode of execution. well, never remember something that you can make a machine remember for you. 

for this use case I'm partial to makefiles. If you aren't familiar with them, they are essentially files that alias longer sets of commands. think of it as a way of having many short bash scripts tailored for a specifc project. 

let's focus on our example here. all we have to do is run `make debug_local` , and we are off to the races. here i'm just printing the top of the help command for covenience, and then setting an environment variable before executing our dlv command. 

This is well and good, but most people find CLI debuggers a little clunky to use. If you are more like me, you want a GUI display. so how do we get a smoother user experience? This is where vscode and the go extension come in. 

I'm gonna skip over the set up steps of installing vscode and the go plugin. plenty of guides do that.  let's start with configuring the debugger in vscode. if you haven't already, you'll need to create a `launch.json`  confiig file for the vscode editor. 

when you first create it, we get a boiler plate configuratiopn for the editor, and it's pretty close to what we want. we want our first configuration to look like this

some notes: request can be "launch" or "attach". we'll touch on that later.  really we are just adding the optional fields to get the equivalent config for our make command.  
```
        {
                "name": "1: launch local example",
                "type": "go",
                "request": "launch",
                "mode": "auto",
                "program": "${workspaceFolder}",
                "args": ["arbitrary_value"],
                "env": {"ENVIRONMENTAL_VARIABLE":"set"}
        },
```

and what do you know, when we flip to the debugger tab, we see it show up on the dropdown. when we run, we can see a pane for our breakpoints. when we actually hit our breakpoint by pinging the server
```
make open
```
we see the variables populate as a tree, for argumetns locals and variables. we can also see the callstack right there, no extra commands. and of course, we can add breakpoints, etc as we could delve. 

going forward,I'm going to focus on the golang launch.json configuration instead of the makefile. but find my repo after the presentaton, I have all the configurations in both forms. 

# example 2: Debugging a tests
now supoose you want to figure out why a test is broken. Delve can do that too! 

just as you would test natively with the `go test` and specifying a package: 
```
go test ./some_package
# we can launch the same with delve
dlv test ./some_package
break some_package/some_package.go:9
continue
print message
```
Let's take a look on how we do this with vscode launch configurations: 

we have to specify "test mode" and then the package, but other than that, it looks like we are good to go! you are probably askng yourself, how on earth would I discover this by msyelf? well, i'd highly recommend reading abou launch.json configurations. You will need to read that on visual studios docs, as well as in the go-code extension. (NOTE not a good spot to put this) . 
# aside: client server model. 
so before we go any further you should probably understand a bit of what's happening under the hood. the  correct mental model will help you reason about configuring your debugger better. 

I'm stealing this slide from Alessandro Arzillli's 2018 gopehrcon talk about the internal architecture of delve. Now, his talk goes into the nitty gritty of it, but the gist of it is that delve in of itself is both a client (representing the UI, and it's service layer) and then a server which maps the symobls of the program to memory addresses and actually manipulates the execution of the program itself.  this separation is important, because this is what allows us to support  running a debugger on say, a different machine, be it a remote server or a container.  

when we use the delve via vscode, a "DAP" or debug adaptor protocol, (which ships witht the vscode-go extension) effectively acts as the new frontend, instead of the CLI interface. it converts the UI actions that are standard to vscode and converts them into rpc requests to the server. it also handles launching the server process, eg headless mode.  (NOTE TO SELF: work shop this)
note: this describes the legacy version of delve (which is currently the default). the newest versions which must be opted into natively support the DAP and require no separate adaptor. 

# Example 3: running process
now that we understand the client server model, it will be more understandable how we can debug increasingly complicated set ups. Let's try debugging a locally running process. 
you'll see in my make file I've identified a somewhate verbose command to build the executable. 

I'd like to briefly call attention to this 'gcflags 

gcflags='all=-N -l'
these are disabling Compiler optimizations and inlining, we won't worry about that. that just makes ithe executable easier to debug 

Now, let's build and run this:
```
make build_debuggable_executable
make run
# now the secret sauce here is to use the 'attach' command
make debug_attach
# and let's try setting a breakpoint 
break some_package/some_package.go:8
#in seperate window curl localhost:8080/ping
print Message
```
Let's talk about  the launch config for this one 

```
"name": "3: launch against running process",
"type": "go",
"request": "attach",
"mode": "local",
"program": "${workspaceFolder}",
"processId": "${command:pickProcess}
```
so there's a few interesting things going on here. 
first we are "attaching" rather than launching. You can essentially think of this as rather than starting the process itself, we are attaching (WORD SMITH) . 
the next point is that we are using the local flag. in this case, its telling us this is a process, rahter than a remote URL to connect to. 

now the pick process is a built in for vscode, and well easier to show how it works. 

Not the most efficient point to debug, but very cool what the built in functions can do. 

# Example 4: debugging a remote server. 
so this one  is probably  a less likely one you'll encounter in your day to day workflow, but more illustrative of our most complicated example, running a docker container debugger.  Here's you do it on the command line

 first we start the server. I want to call attention to the flags we are passing in. We are launching in headless mode, meaning we are running the debugger as just a server. we are also using the multi-client option, so it doesn't get picky about which client it connects to. Finally, we are specifying the port so we can reliably connect to it as opposed to being assigned a random port.  I also specify the api version  to make sure it plays nice with vs-code in the second part of this example. 

this is where the client server model really comes in handy. the connect command is just attaching the frontend to the headless server we are running to
```
make debug_server
make debug_connect
break some_package/some_package.go:8
curl localhost:8080/ping
```
the launch configs aren't terrbily exciting. rahter than specifying an executable name, we are specifying the host and port, a dn using the "remote and attach" configuration, which maps to our connect CLI invocation. 

# Example 5: debugging a docker container. 
okay, I think of this as the most difficult step, but we've built up to this.  the first thing we are going to is take a look at our dockerfile. Now, we do have to modify this so that it can support debugging. we do have to add this go get for the dlv tool to exist within the docker container itself. that' no issue here. (note, if this feels kind of ugly to you, you can always make a second dockerfile exclusively for debuggin with this step included. for this example, I'm going to be overriding the CMD in our main docker file. for now, let's continue. 

first we are going to build the docker container: 
```
make docker_build --dry-run
# you can see we are doing a typical build here. 
make docker_build
# should take a short time, I've built this container before so I can take advantage of the cache. 

#now let's see what we have to do for the run example: 
make docker_debug --dry-run
# there's a lot going on here, let's break it down 
```
the first line  is how we are running the docker container, and the second one is what command we are launching with (remember we are overiding the CMD that runs by default for this container)

for those that aren't super familiar with docker, we just built our container, and are now running it. we are exposing port 40000 (meaning it's reachable outside the docker container, and then mapping to the host machine's port 40000. we could expose it within the dockerfile as well. 

perhaps the more mind-boggling  is this security-opt action. every source more or less says to magically included this otherwise debugging a docker container will not work. i did some extra digging and simply put,  ptrace (a unix system call that allows  one process to control another) is not allowed by default in docker, so you have to disable the associated security feature. 

the second line, the one actually invoking the debugger, should look prety much the same as our example for launching the debug server for our locally running server last example. 
```
make debug_server --dry-run
```

okay, let's launch this. remember we've built our docker container, so we now have to run it, and then connect to it with our client 

```
make docker_debug
make debug_connect
break main.go:25
break some_package/some_package.go:8
continue
continue
curl localhost:8080/ping
ls
```
you can see that while the debugger is working, we are no longer seeing our source code in the actual debugger, which makes life more difficult (although, if you are using a CLI debugger, I assume you are comfortable with difficulty). this problem caused me a lot of consternation at first. I'll skip the troubleshooting steps for now, and outright tell you, this is because the paths in my docker image don't match the paths in my docker file don't match the paths on my local machine, meaning that the debug says "you are here" , but that file doesn't exist on my host machine. the way around this is to specify path subsititution. 
```
vim ~/.dlv/config.yanml 
#there's a lot of global configuration here, 
#uncomment these lines (that I prepared a head of time)
now let's save and rerun. 

make docker_debug
make debug_connect
break main.go:25
continue
#there we go!
``` 
I'm not so much of a masochist to expect someone to do this via CLI though. let's turn to the vscode example

you'll notice 

# Summary
I'm hoping you feel empowered to set up debuggers for your most common go Repos. You'll have to rely on the manuals to build that launch.json (the manuals being vscode docs and the go extension docs (specifically the bits about configuring the launch.json) and a bit of trial and error. the set up can be a hassle, but once you make that launch.json file and lock it into your repo, you are set for your whole team. And i've already touched on some extra mile things you can do.  go out there, and give everyone on your team a new tool in their toolbelt. 
# misc
you can print the stack frame wtih `stack`
note: you should debug a remote configuration via ssh tunnel or on a vpn. not best to have it being on public traffic. 
https://github.com/go-delve/delve/blob/master/Documentation/faq.md

https://code.visualstudio.com/docs/editor/debugging
