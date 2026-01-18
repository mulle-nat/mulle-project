## 4.5.0

Various small improvements


## 4.4.0

feature: add buffered output and pattern matching to mulle-project-all

* mulle-project-all supports `--buffered` output modes for cleaner multi-project execution
* new `--match` flag allows positive pattern filtering alongside existing `--ignore`
* mulle-project-commit now accepts `-m `<message>`` for explicit commit messages
* mulle-project-commit automatically creates new commits when interesting changes detected



* --cmd-file option to mulle-project-all
* -m option for mulle-project-commit
* --fallback-commit option for mulle-project-releasenotes


feature: add AI-assisted commit message generation

* new mulle-project-ai tool for AI-powered project management tasks
* AI-assisted commit message generation following project conventions
* ignore list support in sourcetree-doctor to exclude problematic nodes
* version diff capability to determine semantic version changes
* new word-replace utility for text manipulation


* new AI scripts

* much improved demo runner
* `new_repo` now supports codeberg


## 4.3.0

* --cmd-file option to mulle-project-all
* -m option for mulle-project-commit


feature: add AI-assisted commit message generation

* new mulle-project-ai tool for AI-powered project management tasks
* AI-assisted commit message generation following project conventions
* ignore list support in sourcetree-doctor to exclude problematic nodes
* version diff capability to determine semantic version changes
* new word-replace utility for text manipulation


* new AI scripts

* much improved demo runner
* `new_repo` now supports codeberg


### 4.2.1

* added support fot githubusercontent in the properties.plist generator

* need to update `cmake_minimum_required` because cmake has a weird concept of min required
* mulle-project-version should now be able to update `.._MAJOR` `.._MINOR` `.._PATCH` as well
* mulle-project-extension-versions renamed to mulle-project-version-extensions for the sake of completion
* mulle-project-all now takes --skip as an alias for --ignore

* fix sed command for BSDs

## 4.2.0


* mulle-project-all now also uses more intuitive --from --after and --until options
* the replacement of "sde" with "mulle-sde" in the command string is now less buggy
* mulle-project-versioncheck now emits better error messages if the versioning doesnt match
* fix for include paths in mulle-project-demo


### 4.1.3

* try to fix mulle-project-pacman-pkg for mulle-core workflow

### 4.1.1

* rename --skip-until option to --start-from (but keep old name as well)

## 4.1.0

* add some new commands, improve mulle-replace to be more debuggable


* change master to develop in prelease

feat: modernize project structure and improve version handling

* Switch default branch strategy to master/develop
  - Change release branch to master for modern git flow
  - Make develop the default working branch
  - Update branch references across scripts
  - Fix branch validation and push checks

* Enhance version management
  - Add CMake version support in mulle-project-version
  - Parse and update VERSION field in project() calls
  - Support reading/writing CMakeLists.txt versions
  - Add --no-cmake flags for version control

* Improve repository management
  - Fix gitolite repository creation with git pull
  - Update mulle-project-new-repo defaults
  - Fix submodule paths and branch handling
  - Support branch specification in git submodules

* Other improvements
  - Fix path variables to use `CMAKE_CURRENT_SOURCE_DIR`
  - Add language/dialect support in properties
  - Add fake alias expansion in mulle-project-all
  - Fix package description handling

* mulle-project-new-demos renamed to mulle-project-demo


# 4.0.0

feat: modernize project structure and improve version handling

* Switch default branch strategy to master/develop
  - Change release branch to master for modern git flow
  - Make develop the default working branch
  - Update branch references across scripts
  - Fix branch validation and push checks

* Enhance version management
  - Add CMake version support in mulle-project-version
  - Parse and update VERSION field in project() calls
  - Support reading/writing CMakeLists.txt versions
  - Add --no-cmake flags for version control

* Improve repository management
  - Fix gitolite repository creation with git pull
  - Update mulle-project-new-repo defaults
  - Fix submodule paths and branch handling
  - Support branch specification in git submodules

* Other improvements
  - Fix path variables to use `CMAKE_CURRENT_SOURCE_DIR`
  - Add language/dialect support in properties
  - Add fake alias expansion in mulle-project-all
  - Fix package description handling

* mulle-project-new-demos renamed to mulle-project-demo


## 3.6.0

* fix mulle-project-all so that trailing and leading spaces in the REPOS lines are ignored
* fix for missing inclusion of parents generic headers
* also copy craftinfos from parent
* mulle-replace does not bail anymore if it encounters a directory in the list of files to work on


### 3.5.1

* Various small improvements

## 3.4.0

* added mulle-project-github-rerun
* fix mulle-plist-convert (now mulle-pq) be a hard requirement


## 3.3.0

* added mulle-project-new-rep and mulle-project-github-description
* add --word replace option to mulle-replace
* fix multiple files input in mulle-gitignore
* mulle-project-all can now write a sublime text "meta" project file with --sublime
* new tool **mulle-resolve-symlinks** resolves symlinks to files
* new executable **mulle-project-clib-json** to support clib
* new executable mulle-project-properties-plist to support mulle-readme-cms
* mulle-project-pacman creates PKGBUILD files for linux/arch pacman


## 3.2.0

* fix default homebrew formula
* update mulle-project-version to be able to mirror version in xcodeproj
* add --skip-past to mulle-project-all


### 3.1.2

* new --skip-until and --skip-from flags for mulle-project-all

### 3.1.1

* Various small improvements

## 3.1.0

* new tool mulle-gitignore
* mulle-replace can now deal with multiple files
* new command mulle-project-gitignore


# 3.0.0

* new executable mulle-project-reposfile to compose a REPOS file from many REPOS files
* big function rename to `<tool>`::`<file>`::`<function>` to make it easier to read hopefully
* add --only-test and relatives
* mulle-project-all has changed a lot. To hit all projects use -a, the default is now main only
* moved to mulle-bashfunction 4.0


## 2.4.0

* new commands **mulle-project-commit, mulle-project-extension-versions, mulle-project-github-status**
* new commands **mulle-sourcetree-doctor, mulle-sourcetree-squash-prerelease, mulle-project-all**
* new command **mulle-replace**
* improved mulle-project-releasenotes

## 2.3.0

* i386 support for travis


### 2.2.1

* improved support for non mulle-sde projects with a .travis.d folder nonetheless

## 2.2.0

* new scripts mulle-project-travis-ci-prerelease mulle-project-prerelease mulle-project-local-travis mulle-project-add-missing-branch-identifier


## 2.1.0

* moved to mulle-bashfunctions v2
* new script mulle-project-distcheck
* rename --set-version to --set


### 2.0.6

* add usage info
* potential shell script bugs removed
* small beauty fixes in code

### 2.0.5

* more fine-grained control over distribute functionality

### 2.0.4

* fix post-release, add mulle-project-redistribute

### 2.0.3

* better commandline override of some file settings

### 2.0.2

* fix cmake packaging

### 2.0.1

* too many changes to list
* added a mulle-sde extension for convenient initalization
* use .mulle folder instead of mulle-project (mulle-env will convert this)

# 2.0.0

* too many changes to list
* added a mulle-sde extension for convenient initalization
* use .mulle folder instead of mulle-project (mulle-env will convert this)


### 1.2.3

* fix various fails and uglinesses

### 1.2.2

* fix homebrew install ruby script

### 1.2.1

* remove obsolete file mulle-project-init

## 1.2.0

* use mulle-bashfunctions more and some more improvements


## 1.1.0

* Various small improvements


### 1.0.1

* wean of mulle-bootstrap a little

# 1.0.0

* move to mulle-sde, remove some obsolete stuff
* remove obsolete files


## 0.1.0

* Various small improvements


### 5.2.1

* Various small improvements

## 5.2.0

* mulle-project-debian installs into /usr instead of / by default
* `--first-increment-zero` renamed to `--first-patch-zero`
* zero is now the new default for patch
* will now read a file called post-release.sh and execute a function called post_release on a successful install


## 5.1.0

* new options and bug fixes


### 5.1.1

* Various small improvements

### 5.0.1

* fix unsightly error, if publisher-tap is empty

# 5.0.0

* move the install part of mulle-project into mulle-project-init
* improved VERSION checking for mulle-homebrew
* release-info.sh is now called version-info.sh


## 4.2.0

* simplify release.sh.template even more by putting common stuff into mulle-files.sh

## 4.1.0

* do missing publisher check in the template, this allows the absence of
`formula-info.sh`.
* improve **mulle-project-get-version** to work with existing -info.sh files


# 4.0.0

mulle-hombrew used to be used as an embedded project. This is no more.
You can install it via `brew` for example or put it into your regular
dependencies (`.buildtools/repositories` instead of
`.buildtools/embedded_repositories)


#### The meaning of PROJECT and NAME has changed

* PROJECT is now simply the (GitHub) repository name
* NAME is the brew formula filename without .rb extension

#### Other changes

* simplified release.sh
* use two (three) .sh files release-info.sh and formula-info.sh for customization. This allows (in many cases) to upgrade the release script with mulle-project install w/o having to re-edit the release.sh file
* new exposed version functionality via mulle-project-get-version
* you can choose to not generate a formula if so desired, simply remove formula-info.sh
* now checks if remotes require merging before tagging
* add mulle-project-untag because I notoriusly forget to update the dox

### 3.4.4

* improve error messages for common problems

### 1.0.4

* improve error messages for broken installations
