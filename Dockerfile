from golang
#8080 is default port for gin-gonic, 
EXPOSE 8080 

WORKDIR /app
RUN go get github.com/go-delve/delve/cmd/dlv
COPY . .
#our go program requires this argument
ENV ENVIRONMENTAL_VARIABLE=set

RUN go build -o main main.go
CMD ["./main", "somevalue"]

#we can invoke the debugger via docker run by uncommenting this CMD line
#CMD [ "dlv", "debug", "main.go", "--listen=:40000", "--headless=true", "--api-version=2", "--log" ]
