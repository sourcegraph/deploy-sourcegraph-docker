package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/sourcegraph/sourcegraph/enterprise/dev/ci/images"
)

func main() {
	if len(os.Args) != 3 {
		log.Fatal("constraint, directory arguments must be provided")
	}
	var (
		constraint = os.Args[1]
		dir        = os.Args[2]
	)
	args := []string{
		"run",
		"github.com/sourcegraph/update-docker-tags",
	}
	for _, image := range images.DeploySourcegraphDockerImages {
		if constraint != "" {
			args = append(args, fmt.Sprintf("-enforce=sourcegraph/%s=%s", image, constraint))
		} else {
			args = append(args, fmt.Sprintf("-update=sourcegraph/%s", image))
		}
	}
	args = append(args, dir)
	log.Println(strings.Join(args, " "))

	cmd := exec.Command("go", args...)
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	if err := cmd.Run(); err != nil {
		log.Fatal((err))
	}
}
