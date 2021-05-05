package main

import (
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"golang.org/x/mod/semver"
)

var verbose bool

func main() {
	flag.BoolVar(&verbose, "verbose", false, "print all paths visited")

	flag.Parse()

	branch, err := getBranch()
	if err != nil {
		log.Fatalf("when getting branch %s", err)
	}

	if !isReleaseBranch(branch) {
		fmt.Fprintf(os.Stderr, "branch %q is not a release branch\n", branch)
		os.Exit(0)
	}

	paths := flag.Args()
	err = validate(paths)
	if err != nil {
		log.Fatal(err)
	}
}

func validate(paths []string) error {

	var validationErrors []validationError
	for _, p := range paths {
		err := filepath.WalkDir(p, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return fmt.Errorf("when walking over %q: %s", path, err)
			}

			if d.IsDir() {
				return nil
			}

			ext := filepath.Ext(path)
			if !(ext == ".yaml" || ext == ".yml" || ext == ".sh") {
				return nil
			}
			if verbose {
				log.Println(path)
			}

			b, err := os.ReadFile(path)
			if err != nil {
				return fmt.Errorf("when reading %q: %w", path, err)
			}

			contents := string(b)

			for _, tag := range []string{"insiders", "latest"} {
				if strings.Contains(contents, fmt.Sprintf(":%s", tag)) {
					validationErrors = append(validationErrors, validationError{path, tag})
				}
			}
			return nil
		})

		if err != nil {
			return err
		}

	}

	if len(validationErrors) > 0 {
		message := "FILES WITH INVALID TAGS:"

		for _, e := range validationErrors {
			message = fmt.Sprintf("%s\n%s", message, e.Error())
		}

		return fmt.Errorf(message)
	}

	return nil
}

type validationError struct {
	path string
	tag  string
}

func (e *validationError) Error() string {
	return fmt.Sprintf("%s: %q", e.path, e.tag)
}

func isReleaseBranch(branch string) bool {
	if verbose {
		log.Printf("branch = %q", branch)
	}

	version := strings.TrimPrefix(branch, "publish-")

	if !strings.HasPrefix(version, "v") {
		version = fmt.Sprintf("v%s", version)
	}

	return semver.IsValid(version)
}

func getBranch() (string, error) {
	// tag, branch, git else fail
	tag := os.Getenv("BUILDKITE_TAG")
	if tag != "" {
		return tag, nil
	}

	branch := os.Getenv("BUILDKITE_BRANCH")
	if branch != "" {
		return branch, nil
	}

	branch, err := branchFromGit()
	if err != nil {
		return "", fmt.Errorf("when running git: %w", err)
	}

	if branch != "" {
		return branch, nil
	}

	return "", fmt.Errorf("unable to determine branch")

}

func branchFromGit() (string, error) {
	cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}

	branch := string(out)
	return strings.TrimSpace(branch), nil
}
