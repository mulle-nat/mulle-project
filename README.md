# mulle-homebrew

![mulle-homebrew.iconset/icon_128x128-png](mulle-homebrew.iconset/icon_128x128.png)

**mulle-homebrew** provides a convenience script to tag and release your
[cmake](//cmake.org) based project and publish it on a [homebrew](//brew.sh)
tap. It has been designed, so that it can be used with multiple forks.


#### What the script does

1. Checks that the repository state is clean, no modified files exist
2. Checks that a tag with the current version does not exist
3. Pushes the current development branch (usually **master**) to its **origin** (can be configured)
4. Rebases your **release** (can be configured) branch on your current development branch
5. Tags your repository with the current version
6. Pushes the tagged **release** to **origin**
7. Optionally pushes the tagged **release** to **github**
8. Checks out the the current development branch (usually **master**) again (see 3.)
9. Downloads the source archive for the created tag
10. Calculates the sha256 for the archive
11. Creates the homebrew formula for your project and places it into your tap
12. Commits the tap and pushes it to its default remote

In essence making a tagged release, publishing the release branch and
updating your homebrew formula, reduces to a one-liner like:

```
./bin/release.sh --publisher mulle-nat --publisher-tap 'mulle-kybernetik/software/'
```


## Prerequisites

* you need a homebrew tap (see [below](#below))
* [mulle-build](//github.com/mulle-build/mulle-build) is recommended, but not required


## Installation

Install it via [homebrew](//brew.sh).

```
brew install mulle-kybernetik/alpha/mulle-homebrew
```

## Prepare your project for mulle-homebrew

### 1. Create a customized release.sh script

#### Required: Set project specific variables

First you need to customize a template file. It is customary to keep a
file `release.sh` in the `bin` folder in the top directory of your
project.


```
mulle-homebrew-env install ./bin
```

Then edit it to fit your project setup. This is what you will see:


```
# Define your project and the dependencies for homebrew
# DEPENDENCIES and BUILD_DEPENDENCIES will be evaled later!
# Then run this as
#   ./bin/release.sh --publisher mulle-nat --publisher-tap mulle-kybernetik/alpha/
#

PROJECT="MyProject"      # your project name, requires camel-case
DESC="MyProject does this and that"
LANGUAGE="c"             # c,cpp, objc, bash ...

#
# Keep these commented out, if the automatic detection works well
# enough for you
#
# VERSIONFILE=
# VERSIONNAME=

...
```

Edit `PROJECT` and `DESC` and `LANGUAGE` to match your project.  The language
setting is important for the automatic version detection. It can be any string,
but if your project is written in **C** use `c` and not `C-language` ...


**mulle-homebrew** has an automatic version detection mechanism (see below).
You can tweak it by changing `VERSIONNAME` to the string to search for and
`VERSIONFILE` for the file to search in. Often you don't need to do that though.

Change all these settings to fit your project. In the best case that's all you
need to do.  But best cases are rare occurrences.


#### Optional: Set dependency related variables

If you have dependencies on other homebrew formula at run-time, list them in
`DEPENDENCIES`. List them in `BUILD_DEPENDENCIES` if you only
need them at build-time.

> If your project relies on a related project that is served by a non-official
> tap, it might be useful to use variable prefixes like `${DEPENDENCY_TAP}`.
> That makes the script more reusable, for someone that forks your project.


```
...
#
# Specify needed homebrew packages by name as you would when saying
# `brew install`.
#
# Use the ${DEPENDENCY_TAP} prefix for non-official dependencies.
#
# DEPENDENCIES='${DEPENDENCY_TAP}mulle-concurrent
# libpng
# '
BUILD_DEPENDENCIES='${BOOTSTRAP_TAP}mulle-bootstrap
${BOOTSTRAP_TAP}mulle-build'

#######
# If you are using mulle-build, you don't hafta change anything after this
#######
...
```

If you can use **mulle-brew** to build an install your project, then you
are all done.

> **mulle-brew** can build Xcode, cmake and autoconf projects. If you use **cmake**
> don't forget to specify it as a dependency.


#### Optional: Emit lines for building your project without mulle-build

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

### 2. Configure versioning

If you keep your version in a header file, it is assumed to be in a
**major.minor.patch** format. The header file's name by default is
`src/version.h`, but that can be changed with `VERSIONFILE`. The name
of the version identifier can be changed with `VERSIONNAME`, if
**mulle-homebrew** can not deduce it from the `PROJECT_NAME` setting.

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

The version is under your control, **mulle-homebrew** will never change it.


### 3. Test your release.sh script

Test the script from your project root. You need to give it the publisher,
which is your user name, and the homebrew tap to publish the release to
(note the trailing slash character `/`). The `release.sh` can be started with
`-n`, which performs a dry run without doing anything to your project or
repository. Also you need to specify where the generate formula should be put. That is done somewhat indirectly with `--taps-location` and `--publisher-tap`.

```
./bin/release.sh -v -n --taps-location ~/taps --publisher mulle-nat --publisher-tap 'mulle-kybernetik/software/'
```

> #### Tip
>
> If your homebrew tap is in the parent directory of your project, you can omit
> the `--taps-location` option.
>
> Here is an example if the taps are located elsewhere. If your taps path is
> `/home/nat/mulle-kybernetik/taps/homebrew-software`
> the `--taps-location` is the parent directory `/home/nat/mulle-kybernetik/taps`.
> and `--publisher-tap` is `mulle-kybernetik/software/`


If the output looks good, then do the release:

```
./bin/release.sh --taps-location ~/taps --publisher mulle-nat --publisher-tap 'mulle-kybernetik/software/'
```


## Script Variables

Variables can be set via a commandline option. The value for the variable
is the argument following the option. So for example `--publisher nat` is
treated as `PUBLISHER='nat'`.

## Required Variables

Variable        | Option            | Description
----------------|-------------------|------------------------------------------
`DESC`          |     none          | Description of your project, used in formula
`LANGUAGE`      |     none          | Main language of your project: `c`,`cpp`, `objc` or anything else
`PROJECT`       |     none          | Name of your project in [Camel case](https://en.wikipedia.org/wiki/Camel_case). Used to derive formula name amongst other things.
`PUBLISHER_TAP` | `--publisher-tap` | tap to use for publishing the formula. Needs trailing slash
`PUBLISHER`     | `--publisher`     | Your github user name


## Optional Variables

Variable         | Option             | Description
-----------------|--------------------|------------------------------------------
`ARCHIVE_URL`    | `--archive-url`    | URL of the source archive.
`BOOTSTRAP_TAP`  | `--bootstrap-tap`  | Tap to use for depends_on => build in formulas
`BRANCH`         | `--branch`         | Branch to use as release branch
`DEPENDENCY_TAP` | `--dependency-tap` | Tap to use for depends_on in formulas
`GITHUB`         | `--github`         | Git remote github
`HOMEPAGE_URL`   | `--homepage-url`   | URL of the homepage to use for the formula.
`ORIGIN`         | `--origin`         | Git remote origin
`TAG_PREFIX`     | `--tag-prefix`     | Prefix to use with version to create the tag
`TAG`            | `--tag`            | Tag to use, instead of version
`TAPS_LOCATION`  | `--taps-location`  | Where your taps are stored on your filesystem.
`VERSIONFILE`    |    none            | Location of the version file
`VERSIONNAME`    |    none            | Name of the #define to search for


## User Variables

You can specify your own variables in the same manner, with any `--` option.
An option `--foo 'VfL Bochum 1848'` will create a global variable called
`FOO` set to the string "VfL Bochum 1848".

> In that way you could also specify `DESC` or `PROJECT`. But it is generally
> not recommended.



## Miscellaneous

### How to setup a homebrew tap on github.com


On [github.com](https://github.com) create a repository with a "homebrew-"
prefixed name. If your tap is supposed to be accessed as "software" call it
"homebrew-software". If your github user name is `mulle-nat`, you could then
access this tap with `brew tap mulle-nat/software`.

