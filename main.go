package main

import (
	"fmt"
	"os"

	"github.com/getbread/debug-examples/some_package"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": some_package.GetMessage(),
		})
	})
	playground()
	r.Run() // listen and serve on 0.0.0.0:8080 (for windows "localhost:8080")
}

//init runs automatically before main (built in feature of golang)
func init() {
	envVar := os.Getenv("ENVIRONMENTAL_VARIABLE")
	if envVar == "" {
		fmt.Printf("envVar not set! ")
		os.Exit(1)
	}
	argVar := os.Args[1]
	if argVar != "somevalue" {
		fmt.Printf("argument not set!")
		os.Exit(2)
	}
	fmt.Printf("initialization passed!")
	fmt.Printf("extra line")
}

func playground() {
	j := 0
	a := 0
	b := 0
	for i := 0; i < 100; i++ {
		j = j + i
		a = i
		b = i
	}
	fmt.Print(a + b)
}
