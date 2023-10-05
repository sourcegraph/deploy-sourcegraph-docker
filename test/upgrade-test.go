package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
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
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name:    "verbose",
				Aliases: []string{"v"},
				Usage:   "Stream verbose output to stdout.",
			},
		},
		Commands: []*cli.Command{
			{
				Name:    "standard",
				Aliases: []string{"std"},
				Usage:   "Runs a standard upgrade test. between specified versions \n\nExample:\n\nupgrade-test standard -vs 5.0.0,5.1.0",
				Flags: []cli.Flag{
					&cli.StringSliceFlag{
						Name:     "versions",
						Aliases:  []string{"vs"},
						Usage:    "A sequence of versions to do standard upgrades through.",
						Required: true,
					},
					&cli.BoolFlag{
						Name:    "order-versions",
						Aliases: []string{"ovs"},
						Usage:   "Order versions in the sequence provided by the user, before commencing upgrades.",
					},
				},
				Action: func(cCtx *cli.Context) error {
					ctx := cCtx.Context
					// get flags
					verbose := cCtx.Bool("verbose")
					order := cCtx.Bool("order-versions")
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

					env, err := initTestEnv(ctx, verbose)
					if err != nil {
						return fmt.Errorf("Failed to initialize env: %w", err)
					}
					defer env.cleanup()

					if err := testStandardUpgrade(ctx, env, verbose, order, versions); err != nil {
						return fmt.Errorf("Standard upgrade failed: %w", err)
					}
					return nil
				},
			},
			{
				Name:    "multiversion",
				Aliases: []string{"mvu"},
				Usage:   "Runs a multiversion upgrade between two specified versions \n\nExample:\n\nupgrade-test multiversion  -f 5.0.0 -t 5.1.0",
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
					ctx := cCtx.Context
					// get flags
					verbose := cCtx.Bool("verbose")
					from, err := semver.NewVersion(cCtx.String("from"))
					if err != nil {
						return fmt.Errorf("Invalid 'from' version: %s", cCtx.String("from"))
					}
					to, err := semver.NewVersion(cCtx.String("to"))
					if err != nil {
						return fmt.Errorf("Invalid 'to' version: %s", cCtx.String("to"))
					}
					env, err := initTestEnv(ctx, verbose)
					if err != nil {
						return fmt.Errorf("Failed to initialize env: %w", err)
					}
					defer env.cleanup()

					// Test multiversion upgrade between specified versions
					if err := testMultiversionUpgrade(ctx, env, verbose, from, to); err != nil {
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

// Test env is used to track the state of the test environment, run docker-compose commands, and clean up after the test.
type testEnv struct {
	ctx     context.Context
	tmpDir  string
	dcDir   string
	verbose bool
	cleanup func()
}

// initTestEnv
// - clones the deploy-sourcegraph-docker repo into a temp directory,
// - prunes ALL docker volumes,
// - kills all running containers
//
// Warning this clears all containers/volumes on the host!
func initTestEnv(ctx context.Context, verbose bool) (*testEnv, error) {
	fmt.Println("Initializing test environemt ...")
	// Clear current docker environment
	if err := dockerClean(ctx, verbose); err != nil {
		return nil, fmt.Errorf("failed to clean docker environment during initialization: %w", err)
	}
	if err := dockerPrune(ctx, verbose); err != nil {
		return nil, fmt.Errorf("failed to run docker prune during initialization: %w", err)
	}

	// Create a temp directory
	tmpDir, err := os.MkdirTemp("", "upgrade-test")
	if err != nil {
		return nil, fmt.Errorf("Failed to create temp directory: %w", err)
	}
	if verbose {
		fmt.Printf("Created temp directory: %s\n", tmpDir)
	}
	// Clone the deploy-sourcegraph-docker repo into the tmp directory
	if verbose {
		err := run.Cmd(ctx, "git", "clone", "https://github.com/sourcegraph/deploy-sourcegraph-docker.git").
			Dir(tmpDir).
			Run().Stream(os.Stdout)
		if err != nil {
			return nil, fmt.Errorf("failed to clone deploy-sourcegraph-docker repo: %w", err)
		}
		fmt.Println("Cloned deploy-sourcegraph-docker repo to: ", filepath.Join(tmpDir, "deploy-sourcegraph-docker"))
	} else {
		if err := run.Cmd(ctx, "git", "clone", "https://github.com/sourcegraph/deploy-sourcegraph-docker.git").
			Dir(tmpDir).Run().Wait(); err != nil {
			return nil, fmt.Errorf("failed to clone deploy-sourcegraph-docker repo: %w", err)
		}
	}
	// Create cleanup function to remove the temp directory
	cleanup := func() {
		if err := os.RemoveAll(tmpDir); err != nil {
			fmt.Printf("Failed to remove temp directory(%s): %v", tmpDir, err)
		}
		if err := dockerClean(ctx, verbose); err != nil {
			fmt.Printf("failed to clean docker environment after testing: %v", err)
		}
		return
	}
	// do init things
	return &testEnv{
		ctx:     ctx,
		tmpDir:  tmpDir,
		dcDir:   filepath.Join(tmpDir, "deploy-sourcegraph-docker", "docker-compose"),
		verbose: verbose,
		cleanup: cleanup,
	}, nil
}

// checkout a version tag
func (env *testEnv) gitCheckoutVersion(version *semver.Version) error {
	fmt.Println("Checking out version " + fmt.Sprintf("v%s", version.String()))
	if env.verbose {
		err := run.Cmd(env.ctx, "git", "checkout", fmt.Sprintf("v%s", version.String())).
			Dir(env.dcDir).
			Run().Stream(os.Stdout)
		if err != nil {
			return fmt.Errorf("failed to checkout version %s: %s", fmt.Sprintf("v%s", version.String()), err)
		}
	} else {
		err := run.Cmd(env.ctx, "git", "checkout", fmt.Sprintf("v%s", version.String())).
			Dir(env.dcDir).
			Run().Wait()
		if err != nil {
			return fmt.Errorf("failed to checkout version %s: %s", fmt.Sprintf("v%s", version.String()), err)
		}
	}
	return nil
}

// Get latest migrator version
func (env *testEnv) getLatestMigrator() (*semver.Version, error) {
	tags, err := run.Cmd(env.ctx, "git", "for-each-ref", "--format", "'%(refname:short)'", "refs/tags").
		Dir(env.dcDir).Run().Lines()
	if err != nil {
		return nil, err
	}
	// Loop through tags and find the latest semver tag
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

	if env.verbose {
		fmt.Println("Latest version found: " + latest.String())
	}
	return latest, nil
}

// composeUpTimeout creates a timed context to handle for the failure of migrator during `docker-compose up`
// Migrator "up" in docker-compose can crash loop if it fails, with the migrator continually trying to run the "up" command
// and the frontend waiting to initialize after migrator's successful completion.
//
// This command has a 80 sec timeout and will check the migrator logs to display the failure if the timeout is reached.
func (env *testEnv) composeUpTimeout(images ...string) error {
	timeout := 80 * time.Second
	tCtx, cancel := context.WithTimeout(env.ctx, timeout)
	defer cancel()

	done := make(chan error)

	go func() {
		err := env.composeUp(images...)
		done <- err
	}()

	select {
	case err := <-done:
		return err
	case <-tCtx.Done():
		fmt.Println("\nDocker-compose up timed out afer 60 seconds, checking migrator logs for failure...")
		if err := run.Cmd(env.ctx, "docker", "logs", "migrator").Run().Stream(os.Stdout); err != nil {
			return fmt.Errorf("Error checking migrator logs: %s\n", err)
		}
		return fmt.Errorf("migrator failed docker-compose up after timeout, check logs for details.)")
	}
}

// Docker compose up
func (env *testEnv) composeUp(images ...string) error {
	fmt.Println("Starting docker-compose up...")
	if env.verbose {
		if err := run.Cmd(env.ctx, append([]string{"docker-compose", "up", "-d"}, images...)...).
			Dir(env.dcDir).
			Run().Stream(os.Stdout); err != nil {
			return fmt.Errorf("failed to run docker-compose up: %w", err)
		}
	} else {
		if err := run.Cmd(env.ctx, append([]string{"docker-compose", "up", "-d"}, images...)...).
			Dir(env.dcDir).
			Run().Wait(); err != nil {
			return fmt.Errorf("failed to run docker-compose up: %w", err)
		}
	}
	return nil
}

// Docker compose up
func (env *testEnv) composeDown(images ...string) error {
	fmt.Println("Starting docker-compose down...")
	if env.verbose {
		if err := run.Cmd(env.ctx, append([]string{"docker-compose", "down", "--remove-orphans"}, images...)...).
			Dir(env.dcDir).
			Run().Stream(os.Stdout); err != nil {
			return fmt.Errorf("failed to run docker-compose down: %w", err)
		}
	} else {
		if err := run.Cmd(env.ctx, append([]string{"docker-compose", "down", "--remove-orphans"}, images...)...).
			Dir(env.dcDir).
			Run().Wait(); err != nil {
			return fmt.Errorf("failed to run docker-compose down: %w", err)
		}
	}
	return nil
}

// Standard upgrade test tests the migrator `up` command, iterating over a slice of versions in the order provided.
func testStandardUpgrade(ctx context.Context, env *testEnv, verbose, ordered bool, versions []*semver.Version) error {
	if ordered {
		sort.Sort(semver.Collection(versions))
	}
	for _, version := range versions {
		// git checkout version tag
		if err := env.gitCheckoutVersion(version); err != nil {
			return fmt.Errorf("failed to checkout version %s: %s", version, err)
		}
		// Bring up instance with migrator "up" default
		if err := env.composeUpTimeout(); err != nil {
			return fmt.Errorf("failed to run docker-compose up at version %s: %s", version, err)
		}
		// Check for drift and other "up" operations
		if err := validateUpgrade(ctx, env, verbose, version); err != nil {
			return fmt.Errorf("Error validating upgrade: %s", err)
		}
		// Bring down deployment
		if err := env.composeDown(); err != nil {
			return fmt.Errorf("failed to run docker-compose down at version %s: %s", version, err)
		}
	}
	return nil
}

// Multiversion upgrade test tests the migrator `upgrade` command.
func testMultiversionUpgrade(ctx context.Context, env *testEnv, verbose bool, from, to *semver.Version) error {
	// git checkout and initialize deployment
	if err := env.gitCheckoutVersion(from); err != nil {
		return fmt.Errorf("failed to checkout version %s: %s", from, err)
	}
	if err := env.composeUpTimeout(); err != nil {
		return fmt.Errorf("failed to run docker-compose up %s init: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	// Check for schema drift init of "from" version
	if err := migratorDrift(ctx, env, verbose, from, "frontend"); err != nil {
		return fmt.Errorf("schema drift detected on initial deploy at %s: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	if err := migratorDrift(ctx, env, verbose, from, "codeintel"); err != nil {
		return fmt.Errorf("schema drift detected on initial deploy at %s: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	if err := migratorDrift(ctx, env, verbose, from, "codeinsights"); err != nil {
		return fmt.Errorf("schema drift detected on initial deploy at %s: %s", fmt.Sprintf("v%s", from.String()), err)
	}
	// Bring down init deployment
	if err := env.composeDown(); err != nil {
		return fmt.Errorf("failed to run docker-compose down at %s: %s", from, err)
	}

	// Start just the dbs to be targeted by migrator
	if err := env.composeUp("pgsql", "codeintel-db", "codeinsights-db"); err != nil {
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
		if err := migratorUpgrade(ctx, verbose, from, to, "-ignore-migrator-update"); err != nil {
			return fmt.Errorf("multiversion upgrade from %s to %s failed: %s", from, to, err)
		}
	} else {
		if err := migratorUpgrade(ctx, verbose, from, to); err != nil {
			return fmt.Errorf("multiversion upgrade from %s to %s failed: %s", from, to, err)
		}
	}
	// git checkout "to" version and start the deployment
	if err := env.gitCheckoutVersion(to); err != nil {
		return fmt.Errorf("failed to checkout version %s: %s", to, err)
	}
	if err := env.composeUpTimeout(); err != nil {
		return fmt.Errorf("failed to run final docker-compose up at %s: %s", to, err)
	}
	// Validate the migrator "upgrade" command accomplished required tasks
	if err := validateUpgrade(ctx, env, verbose, to); err != nil {
		return fmt.Errorf("Error validating upgrade: %s", err)
	}
	if err := env.composeDown(); err != nil {
		return fmt.Errorf("failed to run docker-compose down after upgrade: %s", err)
	}
	return nil
}

// Ensure that the expected steps have correctly executed durring the upgradenv.
// - Check versions.version has been updated
// - Check migration_logs for failures
// - Check for schema drift
func validateUpgrade(ctx context.Context, env *testEnv, verbose bool, version *semver.Version) error {
	fmt.Printf("\nChecking version %s for version update, failed migrations, and drift.", fmt.Sprintf("v%s", version.String()))

	// Validate pgsql database versions.version row was set correctly.
	fmt.Printf("\nChecking that versions.version has been updated... ")
	var versionFromDB bytes.Buffer
	err := run.Cmd(ctx, "docker", "exec", "pgsql",
		"psql", "-U", "sg",
		"-c",
		"'SELECT", "version", "FROM", "versions;'", "-t").Run().Stream(&versionFromDB)
	// Validate upgrade is run after an upgrade is performed and takes the upgrade "to" version.
	// If the db doesn't return the "to" version, error.
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
		fmt.Println("Checking for failed migrations... ")
		var numFailedMigrations bytes.Buffer
		err := run.Cmd(ctx, "docker", "exec", "pgsql",
			"psql", "-U", "sg",
			"-c",
			"'SELECT", "COUNT(*)", "FROM", "migration_logs", "WHERE", "success=false;'", "-t").
			Run().Stream(&numFailedMigrations)
		if err != nil {
			return fmt.Errorf("failed to query pgsql for failed migrations count: %s", err)
		}
		// Check for failed migrations
		if strings.TrimSpace(numFailedMigrations.String()) != "0" {
			return fmt.Errorf("found failed migrations in migration_logs table for version %s", fmt.Sprintf("v%s", version.String()))
		}
	}

	// Check for schema drift with docker run migrator ... command drift
	if err := migratorDrift(ctx, env, verbose, version, "frontend"); err != nil {
		return fmt.Errorf("schema drift detected after multiversion upgrade at %s: %s", fmt.Sprintf("v%s", version.String()), err)
	}
	if err := migratorDrift(ctx, env, verbose, version, "codeintel"); err != nil {
		return fmt.Errorf("schema drift detected after multiversion upgrade at %s: %s", fmt.Sprintf("v%s", version.String()), err)
	}
	if err := migratorDrift(ctx, env, verbose, version, "codeinsights"); err != nil {
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
func migratorDrift(ctx context.Context, env *testEnv, verbose bool, version *semver.Version, db string, migratorArgs ...string) error {
	fmt.Println("Checking for drift with docker run migrator... ")
	// Get latest migrator version
	tag, err := env.getLatestMigrator()
	if err != nil {
		return fmt.Errorf("failed to select latest migrator version: %s", err)
	}
	// Construct the docker run command for migrator
	migratorBase := migratorBaseString(ctx, tag)
	migratorCmd := append(migratorBase, "drift", "--db="+db, "--version="+fmt.Sprintf("v%s", version.String()))
	migratorCmd = append(migratorCmd, migratorArgs...)
	if verbose {
		fmt.Println("Running... ", migratorCmd)
	}
	// Run the constructed docker run migrator command
	if err = run.Cmd(ctx, migratorCmd...).Run().Stream(os.Stdout); err != nil {
		return fmt.Errorf("drift check failed for %s version %s: %s", db, fmt.Sprintf("v%s", version.String()), err)
	} else {
		fmt.Println("No schema drift found in", db)
		return nil
	}
}

// Check drift with docker run migrator
func migratorUpgrade(ctx context.Context, verbose bool, vFrom, vTo *semver.Version, migratorArgs ...string) error {
	fmt.Printf("\nPerforming MVU from %s to %s... ", fmt.Sprintf("v%s", vFrom.String()), fmt.Sprintf("v%s", vTo.String()))
	// Construct the docker run command for migrator
	migratorBase := migratorBaseString(ctx, vTo)
	migratorCmd := append(migratorBase, "upgrade", "--from="+fmt.Sprintf("v%s", vFrom.String()), "--to="+fmt.Sprintf("v%s", vTo.String()))
	migratorCmd = append(migratorCmd, migratorArgs...)
	if verbose {
		fmt.Println("Running...\n", migratorCmd)
	}
	// Run the constructed docker run migrator command
	err := run.Cmd(ctx, migratorCmd...).Run().Stream(os.Stdout)
	if err != nil {
		return fmt.Errorf("multiversion upgrade failed from %s to %s: %s", fmt.Sprintf("v%s", vFrom.String()), fmt.Sprintf("v%s", vTo.String()), err)
	}
	return nil
}

// Docker commands

// Prune docker volumes
func dockerPrune(ctx context.Context, verbose bool) error {
	fmt.Println("Pruning docker volumes...")
	if verbose {
		if err := run.Cmd(ctx, "docker", "volume", "prune", "-a", "-f").Run().Stream(os.Stdout); err != nil {
			return fmt.Errorf("failed to prune docker volumes: %s", err)
		}
	} else {
		if err := run.Cmd(ctx, "docker", "volume", "prune", "-a", "-f").Run().Wait(); err != nil {
			return fmt.Errorf("failed to prune docker volumes: %s", err)
		}
	}
	return nil
}

// Stop and clean all docker containers on init
func dockerClean(ctx context.Context, verbose bool) error {
	fmt.Println("Stopping and cleaning all docker containers...")
	// Get all docker containers to stop and clean
	containers, err := run.Cmd(ctx, "docker", "ps", "-aq").Run().Lines()
	if err != nil {
		return fmt.Errorf("failed to stop and clean all docker containers: %s", err)
	}
	// Don't clean if there are no containers
	if len(containers) != 0 {
		// construct the docker rm command for all containers
		rmCmd := append([]string{"docker", "rm", "-f"}, containers...)
		if verbose {
			if err = run.Cmd(ctx, rmCmd...).Run().Stream(os.Stdout); err != nil {
				return fmt.Errorf("failed to stop and clean all docker containers: %s", err)
			}
		} else {
			if err := run.Cmd(ctx, rmCmd...).Run().Wait(); err != nil {
				return fmt.Errorf("failed to stop and clean all docker containers: %s", err)
			}
		}
	}
	return nil
}
