# mulle-project

![mulle-project logo](mulle-project-128x128.png)

**mulle-project** provides a convenience script to tag and release your
[cmake](//cmake.org) based project and publish it on a [homebrew](//brew.sh)
tap. It has been designed, so that it can be used with multiple forks.


#### What the script does

1. Checks that the repository state is clean, no modified files exist
2. Checks that a tag with the current version does not exist
3. Checks that the remote branches aren't ahead and push would fail
4. Pushes the current development branch (usually **master**) to its **origin** (can be configured)
5. Rebases your **release** (can be configured) branch on your current development branch
6. Tags your repository with the current version
7. Pushes the tagged **release** to **origin**
8. Optionally pushes the tagged **release** to **github**
9. Checks out the the current development branch (usually **master**) again (see 3.)
10. Downloads the source archive for the created tag
11. Calculates the sha256 for the archive
12. Creates the homebrew formula for your project and places it into your tap
13. Commits the tap and pushes it to its default remote

In essence making a tagged release, publishing the release branch and
updating your homebrew formula, reduces to a one-liner like:

```
./bin/release.sh --publisher  --publisher-tap ''
```


## Prerequisites

* you need a homebrew tap (see [below](#below))
* [mulle-build](//github.com/mulle-nat/mulle-build) is recommended, but not required


## Installation

Install it via [homebrew](//brew.sh).

```
brew install /mulle-project
```

## Prepare your project for mulle-project


### 1. Create scripts


Create the default configuration using:

```
mulle-project-env install
```

This will create the following files

File                  | Mode      | Description
----------------------|-----------|------------------
`bin/release.sh`      | Overwrite | The release script
`bin/release-info.sh` | Preserve  | Configuration options for git as a shell script
`bin/formula-info.sh` | Preserve  | Configuration options for project as a shell script

The `...-info.sh` files are just shell scripts that are included by
`bin/release.sh`. Within them you can define the following variables


### 2. Configure versioning

If you keep your version in a header file, it is assumed to be in a
**major.minor.patch** format. The header file's name by default is
`src/version.h`, but that can be changed with `VERSIONFILE`. The name
of the version identifier can be changed with `VERSIONNAME`, if
**mulle-project** can not deduce it from the `PROJECT_NAME` setting.

There are various variations possible, you can use the shifted form and
various unshifted forms:

`version.h`:

```
#define MY_VERSION  ((1 << 20) | (7 << 8) | 10)
#define MY_VERSION  1.7.10
MY_VERSION="1.7.10"
set MY_VERSION '1.7.10'
```

As an alternative you can maintain the version in a file called `VERSION`
in your project root.

`VERSION`:

```
1.7.10
```

The version is under your control, **mulle-project** will never change it.


### 3. Edit release-info.sh

> Check if your version is picked up with `mulle-project-version`.
> If it is, you can skip this step.
>

Variable               | Description
-----------------------|------------------------------
`VERSIONFILE`          | The filename containing the version variable
`VERSIONNAME`          | The name of the version variable

If you can use **mulle-brew** to build an install your project,
then you are all done.

> **mulle-brew** can build Xcode, cmake and autoconf projects. If you use **cmake**
> don't forget to specify it as a dependency.


### 4. Edit formula-info.sh

> If you don't want to create a homebrew formula, simply delete
> `bin/formula-info.sh` and skip this step.

Edit the following values, if the defaults doen't work
for you (see end o)

Variable             | Description
---------------------|------------------------------------------
`BUILD_DEPENDENCIES` | List of brew dependencies for building
`DEPENDENCIES`       | List of brew dependencies for runnung
`DESC`               | Description of your project, used in formula
`LANGUAGE`           | Main language of your project: `c`,`cpp`, `objc` or anything else
`PROJECT`            | Name of your project in [Camel case](https://en.wikipedia.org/wiki/Camel_case). Used to derive formula name amongst other things.
`NAME`               | Formula filename without .rb extension


### 5. Test your release.sh script

Test the script from your project root. You need to give it the publisher,
which is your user name, and the homebrew tap to publish the release to
(note the trailing slash character `/`). The `release.sh` can be started with
`-n`, which performs a dry run without doing anything to your project or
repository. Also you need to specify where the generate formula should be put. That is done somewhat indirectly with `--taps-location` and `--tap`.

```
./bin/release.sh -v -n --taps-location ~/taps --publisher  --tap ''
```

> #### Tip
>
> If your homebrew tap is in the parent directory of your project, you can omit
> the `--taps-location` option.
>
> Here is an example if the taps are located elsewhere. If your taps path is
> `/home/nat/mulle-kybernetik/taps/project-software`
> the `--taps-location` is the parent directory `/home/nat/mulle-kybernetik/taps`.
> and `--tap` is ``


If the output looks good, then do the release:

```
./bin/release.sh --taps-location ~/taps --publisher  --tap ''
```

## Optional: Edit release.sh to build without mulle-build

You will have to change `generate_brew_formula_build` so
that proper build stages of
[formula](https://github.com/Homebrew/brew/blob/master/docs/Formula-Cookbook.md)
are emitted.

Using the code from the cookbook, this is how you would modify
`generate_brew_formula_build` (you usually leave `generate_brew_formula` as is):

```
...

#
# Generate your `def install` `test do` lines here
# if you are not using mulle-build
#
generate_brew_formula_build()
{
#   local project="$1"
#   local name="$2"
#   local version="$3"

  echo <<EOF

  def install
    # ENV.deparallelize
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    # system "cmake", ".", *std_cmake_args
    system "make", "install"
  end

  test do
    system "false"
  end
EOF
}

...
```

## Optional: Create tap-info.sh to set tap information

Instead of passing in parameters, you can place the required information
into `tap-info.sh`.  It is recommended to place this file into `.gitignore`

Variable               | Description
-----------------------|------------------------------
`PUBLISHER`            | Your github name
`PUBLISHER_FULLNAME`   | Your fullname (useful for other tools)
`PUBLISHER_TAP`        | Your tap (like in brew install <tap>/project)
`TAPS_LOCATION`        | The root folder of your taps


## Script Variables

Variables can be set via a commandline option. The value for the variable
is the argument following the option. So for example `--publisher nat` is
treated as `PUBLISHER='nat'`.

### Required Variables

Variable        | Option            | Description
----------------|-------------------|------------------------------------------
`DESC`          |     none          | Description of your project, used in formula
`PROJECT`       |     none          | Name of your project and repository.
`PUBLISHER_TAP` | `--tap`           | The homebrew tap to use for publishing the formula. Needs trailing slash
`PUBLISHER`     | `--publisher`     | Your github user name


### Optional Variables

Variable         | Option             | Description
-----------------|--------------------|------------------------------------------
`ARCHIVE_URL`    | `--archive-url`    | URL of the source archive.
`BOOTSTRAP_TAP`  | `--bootstrap-tap`  | Tap to use for depends_on => build in formulas
`BRANCH`         | `--branch`         | Branch to use as release branch
`DEPENDENCY_TAP` | `--dependency-tap` | Tap to use for depends_on in formulas
`GITHUB`         | `--github`         | Git remote github
`HOMEPAGE_URL`   | `--homepage-url`   | URL of the homepage to use for the formula.
`LANGUAGE`       |     none           | Main language of your project: `c`,`cpp`, `objc` or anything else
`NAME`           |     none           | Formula name without .rb extension. Derived from PROJECT if not specified.
`ORIGIN`         | `--origin`         | Git remote origin
`TAG_PREFIX`     | `--tag-prefix`     | Prefix to use with version to create the tag
`TAG`            | `--tag`            | Tag to use, instead of version
`TAPS_LOCATION`  | `--taps-location`  | Where your taps are stored on your filesystem.
`VERSION`        |    none            | Version
`VERSIONFILE`    |    none            | Location of the version file
`VERSIONNAME`    |    none            | Name of the #define to search for


### User Variables

You can specify your own variables in the same manner, with any `--` option.
An option `--foo 'VfL Bochum 1848'` will create a global variable called
`FOO` set to the string "VfL Bochum 1848".

> In that way you could also specify `DESC` or `PROJECT`. But it is generally
> not recommended.


## Miscellaneous

### How to setup a homebrew tap on github.com


On [github.com](https://github.com) create a repository with a "homebrew-"
prefixed name. If your tap is supposed to be accessed as "software" call it
"homebrew-software". If your github user name is ``, you could then
access this tap with `brew tap /software`.

### My typical release scenario

After I have done various commits like this:

```
git commit -m "* commit on master. comment prefixed by * for releasenotes"
...
git commit -m "boring commit"
...
git commit -m "* another interesting commit"
```


I update the version number:

```
mulle-project-version --increment-patch --write
```

Then I produce updated RELEASENOTES.md:

```
mulle-project-releasenotes RELEASENOTES.md
```

Then add the new version and releasenotes to last commit:

```
git add -u
git commit --amend --no-edit
```

Now release it to the world:

```
./bin/release.sh
```


