package main

import (
	"fmt"
	"os"
	"os/exec"
	"time"
)

func main() {
	postsName := fmt.Sprintf(
		"posts/%s-%s.md",
		time.Now().Format("2006-01-02 15:04"),
		os.Args[1])

	err := exec.Command("hugo", "new", postsName).Run()
	if err != nil {
		panic(err)
	}
}
