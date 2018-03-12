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

* mulle-homebrew-debian installs into /usr instead of / by default
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

* move the install part of mulle-homebrew-env into mulle-homebrew-init
* improved VERSION checking for mulle-homebrew
* release-info.sh is now called version-info.sh


## 4.2.0

* simplify release.sh.template even more by putting common stuff into mulle-files.sh

## 4.1.0

* do missing publisher check in the template, this allows the absence of
`formula-info.sh`.
* improve **mulle-homebrew-get-version** to work with existing -info.sh files


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
* use two (three) .sh files release-info.sh and formula-info.sh for customization. This allows (in many cases) to upgrade the release script with mulle-homebrew-env install w/o having to re-edit the release.sh file
* new exposed version functionality via mulle-homebrew-get-version
* you can choose to not generate a formula if so desired, simply remove formula-info.sh
* now checks if remotes require merging before tagging
* add mulle-homebrew-untag because I notoriusly forget to update the dox

### 3.4.4

* improve error messages for common problems

### 1.0.4

* improve error messages for broken installations
