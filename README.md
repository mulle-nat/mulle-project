# mulle-project

![mulle-project logo](mulle-project-128x128.png)

**mulle-project** facilitates project management tasks, such as

* versioning
* releasenotes
* git tagging
* debian distribution
* homebrew distribution
* local travis-ci like continous integration
* prerelease pushes

Most of these scripts are used during readying a new release of **mulle-objc**.

The process is quite involved and has organically grown over time. For starters
it is recommended to get familiar with `mulle-project-all` and `mulle-project-commit` and `mulle-project-version`.

Later on `mulle-project-sourcetree-doctor` and
`mulle-project-releasenotes` can be of great help.



Command                            | Description
-----------------------------------|-----------------------
`mulle-project-add-missing-branch-identifier` | Massages sourcetree configs for use with `mulle-project-travis-ci-prerelease` (possibly outdated)
`mulle-project-all`                | Execute commands in multiple projects
`mulle-project-ci-prerelease`      | Update `environment-host-ci-prerelease.sh`
`mulle-project-ci-settings`        | Create an environment-host-ci-prerelease file file for prerelease tests
`mulle-project-commit`             | Commit "boring" changes automatically, amending if possible
`mulle-project-debian`             | Create and upload debian packages (own server)
`mulle-project-distcheck`          | Predicts if a `mulle-project-distribute` would fail
`mulle-project-distribute`         | Create and publish releases (github)
`mulle-project-extension-versions` | Maintain version of mulle-sde extensions
`mulle-project-gitignore`          | Add files to .gitignore, prevents duplicates
`mulle-project-git-prerelease`     | Push master into a prerelease branch on github
`mulle-project-github-status`      | Poll github action status for CI state
`mulle-project-init`               | Initial setup and update
`mulle-project-latest-current-tag` | Produce a release blog version info entry
`mulle-project-local-travis`       | Test in a local travis-ci like docker
`mulle-project-package-json`       | Create package.json file
`mulle-project-prerelease`         | Create a debian/git prerelease
`mulle-project-redistribute`       | Hack
`mulle-project-releasenotes`       | Create releasenotes from git logs
`mulle-project-reposfile`          | Combine multiple REPOS files into one
`mulle-project-sloppy-distribute`  | Commit current changes, up the version count and distribute with releasenotes given on commandline
`mulle-project-sourcetree-doctor`  | Basic checks that dependencies are set up correctly
`mulle-project-squash-prerelease`  | Squash multiple prerelease commits for beauty
`mulle-project-tag`                | Create tags for repo and all remotes
`mulle-project-travis-ci-prerelease` | Create an environment-host-travis-ci-prerelease.sh file for prerelease tests
`mulle-project-untag`              | Remove tags from repo and all remotes
`mulle-project-version`            | Examine and change project versions
`mulle-project-versioncheck`       | Create version checks for the preprocessor from dependencies
`mulle-replace`                    | Simple string replacer for mulle-project-all


#### What `mulle-project-distribute` does

1. Checks that the repository state is clean, no modified files exist
2. Checks that a tag with the current version does not exist
3. Checks that the remote branches aren't ahead and push would fail
4. Pushes the current development branch (usually **master**) to its **origin** (can be configured)
5. Rebases your **release** (can be configured) branch on your current development branch
6. Remove "latest" tag from participating repositories
7. Tags your repository with the current version and with "latest"
8. Pushes the tagged **release** to **origin**
9. Optionally pushes the tagged **release** to **github**
10. Checks out the current development branch (usually **master**) again (see 3.)
11. Optional: Downloads the source archive for the created tag
12. Optional: Calculates the sha256 for the archive
13. Optional: Creates the homebrew formula for your project and places it into your tap
14. Optional: Commits the tap and pushes it to its default remote
15. Optional: Runs a post-release step

In essence making a tagged release, publishing the release branch,
updating your homebrew formula and distributing an apt package, reduces to the
one-liner:

```
mulle-project-distribute
```

