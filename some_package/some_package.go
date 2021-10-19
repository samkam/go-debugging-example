package some_package

import "fmt"

var Message = "this is my message"

func GetMessage() string {
	fmt.Printf("\nmessage set to: %s\n", Message)
	return Message
}
