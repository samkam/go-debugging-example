package some_package

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPasses(t *testing.T) {
	expected := Message
	actual := GetMessage()
	assert.Equal(t, actual, expected, "this test should pass")
}

func TestFails(t *testing.T) {
	expected := "this is the incorrect message"
	actual := GetMessage()
	assert.Equal(t, actual, expected, "something is wrong with this test!")
}
