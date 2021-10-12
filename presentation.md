# gophercon talk 


- - - -
# Intro
Hi, I'm Sam Kamenetz, I'm a software engineer at Bread, and I love using debuggers. and I'll candidly admit, it took me a long time to figure out how to use Delve, go's debugger. Debugging a hello world application was easy enough, I was able to stumble along by pressing the debug button in my IDE, but I got flustered by  more complicated set ups I encountered in my day to day job, like debugging a test, or debugging a dockerized application. I decided to take the time to learn the ins and outs of delve, and wanted to share my knowledge. 

This talk isn’t just for debugger enthusiasts, but anyone that's tried to debug their project, and even the debugger skeptical. For all of you, my pitch is this: setting up a debugger requires understanding the nuances of how the debugger, project, and IDE interact. It can feel like too much work to set it up in the middle of hunting down a bug. But here’s the thing, it’s a time investment, but it’s a one time investment.  Once you configure your tooling, you can debug at will, even at the press of a button. from there, it's just setting breakpoints.

we aren't going to focus much on actual debugger commands. I’m assuming you have used a debugger and are familiar with basic operations of setting breakpoints and stepping through code execution, and that'll be sufficient for following along. 

# why debuggers are awesome
First, I’m gonna spend a little time proselytizing debuggers to the skeptical. Have you ever found yourself  writing code like this? 
```
# open bad_main.go in editor
```
where you keep on trying to tweak your print statements and recompiling? No more! A debugger will allow you dynamically print and inspect values. It's better than logging,  lets you find bugs faster, and can even allow you to dynamically change values.

```
launch example 1 debug config in IDE 
break in init. run. inspect local values in main. 
```
imagine these scenarios. 
A function is called by many other functions, and you aren't sure what call chain represents the error case. You can inspect the call stack with a debugger. 
```
set breakpoint, run and inspect call stack. 
```
or your code is working fine, but the test is failing, you can launch a debugger against the test itself. Or perhaps a the code works locally, but not in the docker contaiiner. You can launch a debugger against the docker container. if you are getting a nil pointer dereference, and aren't sure why, you can set breakpoints, and watch the values change from line to line. 

Safe to say, debuggers are very very useful, and make your life easier.

# Forward
For each scenario, I'm going to show you how to launch delve as a command line application, and show how the same configuration works when run through the vscode's gui debugger.  so why the CLI and then vscode? I think the CLI, even if it's not the most ergonomic way to run a debugger, is a good basis for understanding the commands before we introduce layers of our tooling.  

For vscode, I like because it's a common tool that's highly configurable, and has robust debugging capabilities. A lot of my coworkers like using Jet Brain's Goland IDE, since debugging usually (emphasis on usually) works out of the box.  I prefer vscode (in general, and for debugging) because the debug settings are much more flexible (there's some really cool things you can do with it), and easily portable (eg, you can easily include the debug configurations as part of version control, more on that later)

You will need vs code editor  the go-extension configured, and naturally delve install. 

# Example 1
Let's start with a simple web server, running locally on port 8080. and unfortunately for us, it doesn't run when I run it like this: 
```
go run main.go
# lets take a crack at it with the delve debugger
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

now, the last thing I want you to do is commit this to your brain's memory. Never remember something that you can make a machine remember for you. let's save this command somewhere, like a makefile. If you aren't familiar with them, they are essentially files that alias longer sets of commands. Think of it as a way of having many short bash scripts tailored for a specifc project. 

you can see what the command is actually executing like this: 
```
make debug_local --dry-run
# here i'm just printing the top of the help command for covenience, and then setting an environment variable before executing our dlv command.
make debug_local
```

while the CLI debugger works, you probably want a GUI built into your editor. This is where vscode and the go extension come in. 

I'm gonna skip over the set up steps of installing vscode and the go plugin. There are plenty of guides do that.  Let's start with configuring the debugger in vscode. if you haven't already, you'll need to create a `launch.json`  config file for the vscode editor.  I've already created mine. 

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

when we select the debugger tab, we see it show up on the dropdown. Let's ping the server and hit a breakpoint.

```
# break on some_package/some_package.go:8
curl localhost:8080/ping
```
we see the variables populate as a tree, for arguments locals and variables. we can also see the callstack right there. and of course, we can add breakpoints, etc as we could in the CLI application . 


# Example 2: Debugging a tests
Now suppose you want to figure out why a test is broken. Delve can do that too! 

just as you would test natively with the `go test` and specifying a package, you invoke 
```
go test ./some_package
# we can launch the same with delve
dlv test ./some_package
break some_package/some_package.go:9
continue
print Message
```
Let's take a look on how we do this with vscode launch configurations: 

we have to specify "test mode" and then the package, but other than that, it looks like we are good to go!
# Aside: client server model. 
Before we go into more complicated examples, let's talk about how debuggers work. The correct mental model will help you reason about configuring your debugger. 
[Pull up slide]

I'm stealing this slide from Alessandro Arzillli's 2018 gophercon talk about the internal architecture of delve.  His talk goes into full detail of the architecture, but the gist is that delve is contains a client (representing the UI, and it's service layer) and then a server which maps the symobls of the program to memory addresses and manipulates the execution of the program itself.  This separation is important, because this is what allows us to support running a debugger on say, a different machine, be it a remote server or a container.  

When we use the Delve via vscode, a "DAP" or debug adaptor protocol, (which ships witht the vscode-go extension) serves as the new frontend, instead of the CLI interface. it uses the UI actions that are standard to vscode and converts them into rpc requests to the server. it also handles launching the server process, eg, launching the debug server via the  "headless" option 
 
note: this describes the legacy version of delve (which is currently the default). the newest versions which must be opted into natively support the DAP and require no separate adaptor. 

# Example 3: running process
now that we understand the client server model,  Let's try debugging a locally running process. 
you'll see in my make file I've identified a somewhate verbose command to build the executable. 

```
make build_debuggable_executable --dry run
```
I'd like to briefly call attention to this 'gcflags.  this is telling the compiler to disable optimizations and inlining, which can sometimes interfere with debugger execution. 
```
make run --dry-run
make debug_attach
```
 
the rest of the commands are simple,  note that we are using "attach" instead of debug, and using pgrep to find the process id by name. 
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
[open launch.json, example 3] 

first we are "attaching" rather than launching. Rather than starting the process itself (launching) we are connecting to an already running process (attach). 
 
then we are using the "local" flag. in this case, indicating a process , rather than a remote URL to connect to. 

finally we are specifying the process name.   

# Example 4: debugging a remote server. 
Now, let's debug  from a remote server. this isn't a scenario that's as likely to come up in my day to day at least, but It's a good stepping stone to our most complicated example, running a docker container debugger. 

```
make debug_server --dry-run
```

first we are starting a server. I want to call attention to the flags we are passing in. 
1. We launch in headless mode, meaning we are running the debugger as just a server, waiting for a client to connect.
2. we use the multi-client option (meaning multiple clients can connect, sometimes necessary for certain debug interactions, like the --continue flag, to reconnect to a server without restarting. 
3. we specify the port so we can reliably connect to it as opposed to being assigned a random port. 
4. I specify the api version  to make sure it plays nice with vs-code in the second part of this example. 
let's take a look at how we are connecting to this headless debug server
```
make debug_connect --dry-run 
```
this is where the client server model really comes in handy. the connect command is just attaching the frontend to the headless server we are running, specifying the port. 

```
make debug_server
make debug_connect
break some_package/some_package.go:8
curl localhost:8080/ping
```

[open launch.json, example 4] 
the launch configs aren't terrbily exciting. rahter than specifying an executable name, we are specifying the host and port, a dn using the "remote and attach" configuration, which maps to our connect CLI invocation. 

[launch vscode debugger,  run example 4] 

# Example 5: debugging a docker container. 
okay, onto the most diffficult example, debugging a docker. luckily we've built up to this point. First we have to modify our dockerfile to support debugging.
[open Dockerfile]

first we have to add the delve tool 
we do have to add this go get for the dlv tool to exist within the docker container itself. that' no issue here. (note, if this feels kind of ugly to you, you can always make a second dockerfile exclusively for debugging with this step included. for this example, I'm going to be overriding the CMD in our main docker file. for now, let's continue. 

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
 you are probably askng yourself, how on earth would I discover this by msyelf? well, i'd highly recommend reading about launch.json configurations. You will need to read that on visual studios docs, as well as in the go-code extension. (NOTE not a good spot to put this) . 
