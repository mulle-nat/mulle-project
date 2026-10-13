## 4.6.0


* dropped `amalgamate-sources.sh`, superseded by newer tooling
* removed outdated `README-RELEASENOTES.md` instructions


feature: verify sourcetree database before generating CI settings

* mulle-project-ci-settings now validates the sourcetree database before writing and repairs it automatically, refusing to emit an incomplete dependency listing; adds --fix/--no-fix and --fetch/--no-fetch flags
* mulle-project-sourcetree-doctor can now repair archive nodetype/url/tag wrappings with --fix and handles branch wrapping and empty defaults more reliably
* mulle-project-version adds four-number "custom" version support, including tag detection and a new "custom" result from `diff`
* mulle-project-version refuses to overwrite structured files when no version key is supplied, preventing accidental truncation
* mulle-project-commit `--only-amend` now fails immediately when an amend is impossible, while `--safe-amend` amends only unpushed/untagged, non-merge commits
* mulle-project-version-extensions resolves the enclosing `*-developer` project instead of trusting mulle-env, which could report an umbrella project
* **BREAKING** mulle-project-travis-ci-prerelease has been removed


* properly use `MULLE_SDE_REFLECT_DIR` in created file paths


### 4.5.2


* `can_push` now correctly allows pushing branches that don't yet exist on the remote
* missing .mulle/etc/project folder message downgraded from warning to verbose

* convenient --from x --until x coded to pinpoint single repo

### 4.5.1


* `can_push` now correctly allows pushing branches that don't yet exist on the remote
* missing .mulle/etc/project folder message downgraded from warning to verbose

* convenient --from x --until x coded to pinpoint single repo
