package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/Masterminds/semver"
	"github.com/urfave/cli/v2"

	"github.com/sourcegraph/run"
)

// This is the main entry point for a docker-compose upgrade test tool intended for use within CI/CD pipelines, but also usable by developers for quick smoke tests
func main() {
	app := &cli.App{
		Name:  "upgrade-test",
		Usage: "Upgrade test is an upgrade smoke test for Sourcegraph's docker-compose deployment type.",
		Commands: []*cli.Command{
			{
				Name:    "standard",
				Aliases: []string{"std"},
				Usage:   "Runs a standard upgrade test. between specified versions \n\nExample:\n\n./upgrade-test standard -vs 5.0.0,5.1.0",
				Flags: []cli.Flag{
					&cli.StringSliceFlag{
						Name:     "versions",
						Aliases:  []string{"vs"},
						Usage:    "A sequence of versions to do standard upgrades through.",
						Required: true,
					},
				},
				Action: func(cCtx *cli.Context) error {
					ctx := context.Background()
					// Process user provided versions
					userVersions := cCtx.StringSlice("versions")
					var versions []*semver.Version
					for _, v := range userVersions {
						ver, err := semver.NewVersion(v)
						if err != nil {
							return fmt.Errorf("Invalid version: %s", v)
						}

						versions = append(versions, ver)
					}

					currentBranch, err := initTest(ctx)
					if err != nil {
						return fmt.Errorf(err.Error())
					}
					// Reset the branch to the initial state on test completion or error
					defer func(ctx context.Context) error {
						deferErr := exec.CommandContext(ctx, "git", "checkout", "-f", currentBranch).Run()
						if deferErr != nil {
							if err != nil {
								return fmt.Errorf("error: %w; error checking out initial branch %s: %v", err, currentBranch, deferErr)
							} else {
								return fmt.Errorf("Error checking out branch %s: %w", currentBranch, err)
							}
						}
						return nil
					}(ctx)
					if err := testStandardUpgrade(ctx, versions); err != nil {
						return fmt.Errorf("Standard upgrade failed: %w", err)
					}
					return nil
				},
			},
			{
				Name:    "multiversion",
				Aliases: []string{"mvu"},
				Usage:   "Runs a multiversion upgrade between two specified versions \n\nExample:\n\n./upgrade-test multiversion  -f 5.0.0 -t 5.1.0",
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:     "from",
						Aliases:  []string{"f"},
						Usage:    "Sourcegraph version to upgrade from",
						Required: true,
					},
					&cli.StringFlag{
						Name:     "to",
						Aliases:  []string{"t"},
						Usage:    "Sourcegraph version to upgrade to",
						Required: true,
					},
				},
				Action: func(cCtx *cli.Context) error {
					ctx := context.Background()
					from, err := semver.NewVersion(cCtx.String("from"))
					if err != nil {
						return fmt.Errorf("Invalid 'from' version: %s", cCtx.String("from"))
					}
					to, err := semver.NewVersion(cCtx.String("to"))
					if err != nil {
						return fmt.Errorf("Invalid 'to' version: %s", cCtx.String("to"))
					}
					currentBranch, err := initTest(ctx)
					if err != nil {
						return fmt.Errorf("Failed to initialize env: %w", err)
					}
					// Reset the branch to the initial state on test completion or error
					defer func(ctx context.Context) error {
						deferErr := exec.CommandContext(ctx, "git", "checkout", "-f", currentBranch).Run()
						if deferErr != nil {
							if err != nil {
								return fmt.Errorf("error: %w; error checking out initial branch %s: %v", err, currentBranch, deferErr)
							} else {
								return fmt.Errorf("Error checking out branch %s: %w", currentBranch, err)
							}
						}
						return nil
					}(ctx)
					// Test multiversion upgrade between specified versions
					if err := testMultiversionUpgrade(ctx, from, to); err != nil {
						return fmt.Errorf("Multiversion upgrade failed: %w", err)
					}
					return nil
				},
			},
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}

}

// Init test ensures that the instance is running in a fresh environment with the latest git tags of the deploy-sourcegraph-docker repo.
// This includes:
// - Checking that the test is being run in the deploy-sourcegraph-docker repo
// - Fetching latest git tags
// - Getting current branch to reset to after test
// - Checking that specified versions are valid tags
// - Running docker-compose down to ensure there are no orphan containers around on init
//
// Failures in any step will exit before the test begins.
//
// Warning this clears all containers/volumes on the host!
func initTest(ctx context.Context) (string, error) {
	if err := checkRepo(ctx); err != nil {
		log.Fatal("test running in wrong repo:", err)
	}
	if err := exec.CommandContext(ctx, "git", "fetch").Run(); err != nil {
		log.Fatal("failed to fetch tags:", err)
	}

	// Get the current branch to reset to after test completes
	out, err := exec.CommandContext(ctx, "git", "branch", "--show-current").Output()
	if err != nil {
		log.Fatal("failed to get current branch at init: ", err)
	}
	currentBranch := strings.TrimSpace(string(out))

	// Clear current docker environment
	if err := composeDown(ctx); err != nil {
		log.Fatal("failed to run docker-compose down during initialization: ", err)
	}
	if err := dockerPrune(ctx); err != nil {
		log.Fatal("failed to run docker prune during initialization: ", err)
	}
	return currentBranch, err
}

// Standard upgrade test tests the migrator `up` command, iterating over a slice of versions in the order provided.
func testStandardUpgrade(ctx context.Context, versions []*semver.Version) error {
	for _, version := range versions {
		// git checkout version tag
		if err := gitCheckoutVersion(ctx, version); err != nil {
			return fmt.Errorf("failed to checkout version %s: %s", version, err)
		}
		// Bring up instance with migrator "up" default
		if err := composeUpTimeout(ctx); err != nil {
			return fmt.Errorf("failed to run docker-compose up at version %s: %s", version, err)
		}
		// Check for drift and other "up" operations
		if err := validateUpgrade(ctx, version); err != nil {
			return fmt.Errorf("Error validating upgrade: %s", err)
		}
		// Bring down deployment
		if err := composeDown(ctx); err != nil {
			return fmt.Errorf("failed to run docker-compose down at version %s: %s", version, err)
		}
	}
	return nil
}

// Multiversion upgrade test tests the migrator `upgrade` command.
func testMultiversionUpgrade(ctx context.Context, from, to *semver.Version) error {
	// git checkout and initialize deployment
	if err := gitCheckoutVersion(ctx, from); err != nil {
		return fmt.Errorf("failed to checkout version %s: %s", from, err)
	}
	if err := composeUpTimeout(ctx); err != nil {
		return fmt.Errorf("failed to run docker-compose up %s init: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	// Check for schema drift init of "from" version
	if err := migratorDrift(ctx, from, "frontend"); err != nil {
		return fmt.Errorf("schema drift detected on initial deploy at %s: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	if err := migratorDrift(ctx, from, "codeintel"); err != nil {
		return fmt.Errorf("schema drift detected on initial deploy at %s: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	if err := migratorDrift(ctx, from, "codeinsights"); err != nil {
		return fmt.Errorf("schema drift detected on initial deploy at %s: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	// Bring down init deployment
	if err := composeDown(ctx); err != nil {
		return fmt.Errorf("failed to run docker-compose down at %s: %s", from, err)
	}

	// Start just the dbs to be targeted by migrator
	if err := composeUp(ctx, "pgsql", "codeintel-db", "codeinsights-db"); err != nil {
		return fmt.Errorf("failed to run docker-compose up for databases at %s: %s", fmt.Sprintf("v%s", from.String()), err)
	}

	// Here we run the migrator with the "upgrade" command, first we check the version of "to",
	// this is because in v5.1.0 a check is added to ensure migrator is always run at the latest possible image version.
	// For our testing migrator will run the upgrade using the specified "to" version.
	c, err := semver.NewConstraint(">= 5.1.0")
	if err != nil {
		return fmt.Errorf("failed to create semver constraint: %s", err)
	}
	if c.Check(to) {
		if err := migratorUpgrade(ctx, from, to, "-ignore-migrator-update"); err != nil {
			return fmt.Errorf("multiversion upgrade from %s to %s failed: %s", from, to, err)
		}
	} else {
		if err := migratorUpgrade(ctx, from, to); err != nil {
			return fmt.Errorf("multiversion upgrade from %s to %s failed: %s", from, to, err)
		}
	}
	// git checkout "to" version and start the deployment
	if err := gitCheckoutVersion(ctx, to); err != nil {
		return fmt.Errorf("failed to checkout version %s: %s", to, err)
	}
	if err := composeUpTimeout(ctx); err != nil {
		return fmt.Errorf("failed to run final docker-compose up at %s: %s", to, err)
	}
	// Validate the migrator "upgrade" command accomplished required tasks
	if err := validateUpgrade(ctx, to); err != nil {
		return fmt.Errorf("Error validating upgrade: %s", err)
	}
	return nil
}

// Ensure that the expected steps have correctly executed durring the upgrade.
// - Check versions.version has been updated
// - Check migration_logs for failures
// - Check for schema drift
func validateUpgrade(ctx context.Context, version *semver.Version) error {
	fmt.Printf("\nChecking version %s for version update, failed migrations, and drift.", fmt.Sprintf("v%s", version.String()))

	// Validate pgsql database versions.version row was set correctly.
	fmt.Printf("\nChecking that versions.version has been updated ... ")
	var versionFromDB bytes.Buffer
	err := run.Cmd(ctx, "docker", "exec", "pgsql",
		"psql", "-U", "sg",
		"-c",
		"'SELECT", "version", "FROM", "versions;'", "-t").Run().Stream(&versionFromDB)
	if versionFromDB.String() == version.String() {
		return fmt.Errorf("versions.version not updated to %s", fmt.Sprintf("v%s", version.String()))
	} else if err != nil {
		return fmt.Errorf("failed to validate upgraded version %s: %s", fmt.Sprintf("v%s", version.String()), err)
	}
	// Check for failed migrations in migration_logs table. Valid after v3.36.0 when table was introduced
	// If the count of rows in the "migration_logs" table with column "success"=false is greater than 0, error
	c, err := semver.NewConstraint(">= 3.36.0")
	if err != nil {
		return fmt.Errorf("failed to create semver constraint: %s", err)
	}
	if c.Check(version) {
		fmt.Printf("\nChecking for failed migrations ... ")
		var numFailedMigrations bytes.Buffer
		err := run.Cmd(ctx, "docker", "exec", "pgsql",
			"psql", "-U", "sg",
			"-c",
			"'SELECT", "COUNT(*)", "FROM", "migration_logs", "WHERE", "success=false;'", "-t").Run().Stream(&numFailedMigrations)
		if err != nil {
			return fmt.Errorf("failed to query pgsql for failed migrations count: %s", err)
		}
		// Check for failed migrations
		if strings.TrimSpace(numFailedMigrations.String()) != "0" {
			return fmt.Errorf("found failed migrations in migration_logs table for version %s", fmt.Sprintf("v%s", version.String()))
		}
	}

	// Check for schema drift with docker run migrator ... command drift
	if err := migratorDrift(ctx, version, "frontend"); err != nil {
		return fmt.Errorf("schema drift detected after multiversion upgrade at %s: %s", fmt.Sprintf("v%s", version.String()), err)
	}
	if err := migratorDrift(ctx, version, "codeintel"); err != nil {
		return fmt.Errorf("schema drift detected after multiversion upgrade at %s: %s", fmt.Sprintf("v%s", version.String()), err)
	}
	if err := migratorDrift(ctx, version, "codeinsights"); err != nil {
		return fmt.Errorf("schema drift detected after multiversion upgrade at %s: %s", fmt.Sprintf("v%s", version.String()), err)
	}

	return nil
}

// Construct the base string for the docker run migrator commands
func migratorBaseString(ctx context.Context, migratorVersion *semver.Version) []string {
	migratorBase := []string{"docker", "run", "--rm",
		"--name", "migrator_" + migratorVersion.String(),
		"-e", "PGHOST=pgsql",
		"-e", "PGPORT=5432",
		"-e", "PGUSER=sg",
		"-e", "PGPASSWORD=sg",
		"-e", "PGDATABASE=sg",
		"-e", "PGSSLMODE=disable",
		"-e", "CODEINTEL_PGHOST=codeintel-db",
		"-e", "CODEINTEL_PGPORT=5432",
		"-e", "CODEINTEL_PGUSER=sg",
		"-e", "CODEINTEL_PGPASSWORD=sg",
		"-e", "CODEINTEL_PGDATABASE=sg",
		"-e", "CODEINTEL_PGSSLMODE=disable",
		"-e", "CODEINSIGHTS_PGHOST=codeinsights-db",
		"-e", "CODEINSIGHTS_PGPORT=5432",
		"-e", "CODEINSIGHTS_PGUSER=postgres",
		"-e", "CODEINSIGHTS_PGPASSWORD=password",
		"-e", "CODEINSIGHTS_PGDATABASE=postgres",
		"-e", "CODEINSIGHTS_PGSSLMODE=disable",
		"--network=docker-compose_sourcegraph",
		"sourcegraph/migrator:" + migratorVersion.String(),
	}
	return migratorBase
}

// Check drift with docker run migrator, use latest migrator version
func migratorDrift(ctx context.Context, version *semver.Version, db string, migratorArgs ...string) error {
	fmt.Println("Checking for drift with docker run migrator ... ")
	// Get latest migrator version
	tag, err := getLatestMigrator(ctx)
	if err != nil {
		return fmt.Errorf("failed to select latest migrator version: %s", err)
	}
	// Construct the docker run command for migrator
	migratorBase := migratorBaseString(ctx, tag)
	migratorCmd := append(migratorBase, "drift", "--db="+db, "--version="+fmt.Sprintf("v%s", version.String()))
	migratorCmd = append(migratorCmd, migratorArgs...)
	// Run the constructed docker run migrator command
	err = run.Cmd(ctx, migratorCmd...).Run().Stream(os.Stdout)
	if err != nil {
		return fmt.Errorf("drift check failed for %s version %s: %s", db, fmt.Sprintf("v%s", version.String()), err)
	} else {
		fmt.Println("No schema drift found in", db)
		return nil
	}
}

// Check drift with docker run migrator
func migratorUpgrade(ctx context.Context, vFrom, vTo *semver.Version, migratorArgs ...string) error {
	fmt.Printf("\nPerforming MVU from %s to %s ... ", fmt.Sprintf("v%s", vFrom.String()), fmt.Sprintf("v%s", vTo.String()))
	// Construct the docker run command for migrator
	migratorBase := migratorBaseString(ctx, vTo)
	migratorCmd := append(migratorBase, "upgrade", "--from="+fmt.Sprintf("v%s", vFrom.String()), "--to="+fmt.Sprintf("v%s", vTo.String()))
	migratorCmd = append(migratorCmd, migratorArgs...)
	// Run the constructed docker run migrator command
	err := run.Cmd(ctx, migratorCmd...).Run().Stream(os.Stdout)
	if err != nil {
		return fmt.Errorf("multiversion upgrade failed from %s to %s: %s", fmt.Sprintf("v%s", vFrom.String()), fmt.Sprintf("v%s", vTo.String()), err)
	}
	return nil
}

// checkout a version tag
func gitCheckoutVersion(ctx context.Context, version *semver.Version) error {
	fmt.Println("Checking out version " + fmt.Sprintf("v%s", version.String()))
	err := run.Cmd(ctx, "git", "checkout", fmt.Sprintf("v%s", version.String())).Run().Stream(os.Stdout)
	if err != nil {
		return fmt.Errorf("failed to checkout version %s: %s", fmt.Sprintf("v%s", version.String()), err)
	}
	return nil
}

// Docker commands

// Prune docker volumes
func dockerPrune(ctx context.Context) error {
	fmt.Println("Pruning docker volumes...")
	err := run.Cmd(ctx, "docker", "volume", "prune", "-a", "-f").Run().Stream(os.Stdout)
	if err != nil {
		return fmt.Errorf("failed to prune docker volumes: %s", err)
	}
	return nil
}

// composeUpTimeout creates a timed context to handle for the failure of migrator during `docker-compose up`
// Migrator "up" in docker-compose can crash loop if it fails, with the migrator continually trying to run the "up" command
// and the frontend waiting to initialize after migrator's successful completion.
//
// This command has a 80 sec timeout and will check the migrator logs to display the failure if the timeout is reached.
func composeUpTimeout(ctx context.Context, images ...string) error {
	timeout := 80 * time.Second
	tCtx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	done := make(chan error)

	go func() {
		err := composeUp(tCtx, images...)
		done <- err
	}()

	select {
	case err := <-done:
		return err
	case <-tCtx.Done():
		fmt.Println("\nDocker-compose up timed out afer 60 seconds, checking migrator logs for failure...")
		err := run.Cmd(ctx, "docker", "logs", "migrator").Run().Stream(os.Stdout)
		if err != nil {
			return fmt.Errorf("Error checking migrator logs: %s\n", err)
		}
		return fmt.Errorf("migrator failed docker-compose up after timeout, check logs for details.)")
	}
}

// Docker compose up
func composeUp(ctx context.Context, images ...string) error {
	fmt.Println("Starting docker-compose up...")
	path, err := filepath.Abs("../docker-compose")
	if !strings.Contains(path, "deploy-sourcegraph-docker/docker-compose") {
		return fmt.Errorf("docker-compose commands not executed in docker-compose directory: cmd.Dir = %s", path)
	}
	if err != nil {
		return fmt.Errorf("failed to get absolute path for docker-compose: %s", err)
	}
	err = run.Cmd(ctx, append([]string{"docker-compose", "up", "-d"}, images...)...).Dir(path).Run().Stream(os.Stdout)
	if err != nil {
		return fmt.Errorf("failed to run docker-compose up: ", err)
	}
	return nil
}

// Docker compose up
func composeDown(ctx context.Context, images ...string) error {
	fmt.Println("Starting docker-compose down...")
	path, err := filepath.Abs("../docker-compose")
	if !strings.Contains(path, "deploy-sourcegraph-docker/docker-compose") {
		return fmt.Errorf("docker-compose commands not executed in docker-compose directory: cmd.Dir = %s", path)
	}
	if err != nil {
		return fmt.Errorf("failed to get absolute path for docker-compose: %s", err)
	}
	err = run.Cmd(ctx, append([]string{"docker-compose", "down", "--remove-orphans"}, images...)...).Dir(path).Run().Stream(os.Stdout)
	if err != nil {
		return fmt.Errorf("failed to run docker-compose down: ", err)
	}
	return nil
}

//Version Handlers

func getLatestMigrator(ctx context.Context) (*semver.Version, error) {
	tags, err := run.Cmd(ctx, "git", "for-each-ref", "--format", "'%(refname:short)'", "refs/tags").Run().Lines()
	if err != nil {
		return nil, err
	}
	var latest *semver.Version

	for _, tag := range tags {
		v, err := semver.NewVersion(tag)
		if err != nil {
			continue // skip non-matching tags
		}

		if latest == nil || v.GreaterThan(latest) {
			latest = v
		}
	}

	if latest == nil {
		return nil, errors.New("No valid semver tags found")
	}

	return latest, nil
}

// Ensure the test is executed in the right repo
func checkRepo(ctx context.Context) error {
	cr, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return fmt.Errorf("git rev-parse --show-toplevel failed with:  %s", err) ///
	}

	crs := strings.TrimSpace(string(cr))

	if !strings.Contains(crs, "deploy-sourcegraph-docker") {
		return fmt.Errorf("Must run from deploy-sourcegraph-docker repository")
	}

	return nil
}
