from golang
#8080 is default for gin-gonic, 40000 is default for dlv
EXPOSE 8080 40000

WORKDIR /go/src/github.com/getbread/debug-examples/
RUN go get github.com/go-delve/delve/cmd/dlv
COPY . .
# remove any executables built locally
RUN rm -f debuggable_executable && rm -f __debug_bin 
#our go program requires this argument
ENV ENVIRONMENTAL_VARIABLE=set
CMD [ "dlv", "debug", "main.go", "--listen=:40000", "--headless=true", "--api-version=2", "--log" ]
