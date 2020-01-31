package main

import (
	"bytes"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

func main() {
	tag := os.Getenv("TAG")

	out, err := commandOutput("sh", "-c", `rm -rf /tmp/deploy-sourcegraph && git clone https://github.com/sourcegraph/deploy-sourcegraph /tmp/deploy-sourcegraph`)
	check(err)

	out, err = commandOutput("sh", "-c", `cd /tmp/deploy-sourcegraph && git checkout `+tag)
	check(err)

	out, err = commandOutput("sh", "-c", `cd ../deploy-sourcegraph && git grep -oh index.docker.io/sourcegraph/...*`)
	check(err)
	for _, line := range strings.Split(out, "\n") {
		if line == "" {
			continue
		}
		imageName := strings.Split(strings.TrimPrefix(line, "index.docker.io/"), ":")[0]
		imageWithTag := strings.TrimPrefix(line, "index.docker.io/")
		check(replaceRegexpInFiles("*.sh", imageName+`\:.*`, imageWithTag, -1))
	}
}

func commandOutput(cmd string, args ...string) (string, error) {
	c := exec.Command(cmd, args...)
	var buf bytes.Buffer
	if verbose := os.Getenv("VERBOSE"); verbose == "true" {
		c.Stdout = io.MultiWriter(os.Stdout, &buf)
	} else {
		c.Stdout = &buf
	}
	c.Stdin = os.Stdin
	c.Stderr = os.Stderr
	err := c.Run()
	return buf.String(), err
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}

func replaceRegexpInFiles(glob, oldRegexp, newLiteral string, n int) error {
	re, err := regexp.Compile(oldRegexp)
	if err != nil {
		return err
	}
	return replaceInFiles(glob, func(s string) string {
		for _, old := range re.FindAllString(s, n) {
			s = strings.Replace(s, old, newLiteral, n)
		}
		return s
	})
}

func replaceTextInFiles(glob, old, new string, n int) error {
	return replaceInFiles(glob, func(s string) string {
		return strings.Replace(s, old, new, n)
	})
}

func replaceInFiles(glob string, replace func(old string) string) error {
	matches, err := filepath.Glob(glob)
	if err != nil {
		return err
	}
	for _, m := range matches {
		data, err := ioutil.ReadFile(m)
		if err != nil {
			return err
		}
		newData := replace(string(data))
		err = ioutil.WriteFile(m, []byte(newData), 0644)
		if err != nil {
			return err
		}
	}
	return nil
}
