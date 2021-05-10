package some_package

import "fmt"

var Message = "this is my message"

func GetMessage() string {
	fmt.Printf("message set to: %s", Message)
	return Message
}
