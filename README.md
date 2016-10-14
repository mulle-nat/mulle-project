# mulle-homebrew

A convenience script to tag and release something and publish it to
a homebrew tap.

> In it's current state probably NOT that useful for most people.

For this example it is assumed, that you keep your version in a header file,
in this major.minor.patch format:

```
#define MY_VERSION  ((1 << 20) | (7 << 8) | 10)
```


## Usage

Install into local project `./bin` directory

```
echo "https://www.mulle-kybernetik.com/repositories/mulle-homebrew;bin/mulle-homebrew" >> .bootstrap/embedded_repositories
mulle-build
```

Create a `release.sh` script in `./bin`  (to be executed from project root)

```
NAME="my-project"    # your project name as known by git and homebrew

# source mulle-homebrew.sh (clumsily)

. ./bin/mulle-homebrew/mulle-homebrew.sh

# parse options
homebrew_parse_options "$@"

# dial past options
while [ $# -ne 0 ]
do
   case "$1" in
      -*)
         shift
      ;;
      *)
         break;
      ;;
   esac
done


# --- HOMEBREW FORMULA ---
# Information needed to construct a proper brew formula
#
HOMEPAGE="https://www.mulle-kybernetik.com/software/git/${NAME}"
DESC="My useful project"
PROJECT="MyProject"  # for ruby, it requires camel-case
ARCHIVEURL='https://www.mulle-kybernetik.com/software/git/${NAME}/tarball/${VERSION}'  # ARCHIVEURL will be evaled later! keep it in single quotes
DEPENDENCIES=        # other required brew dependencies separated by linefeed


# --- HOMEBREW TAP ---
# Specify to where and under what bame to publish via your brew tap
#
RBFILE="${NAME}.rb"                    # ruby file for brew
HOMEBREWTAP="../homebrew-software"     # your tap repository path


# --- GIT AND HOMEBREW VERSIONING ---
# you have to figure out how to provide the script with a version
# the easiest way is to use the predefined `get_header_version`.
# Which is provided by `mulle-homebrew.sh`
#
HEADER="src/my_project.h"
VERSIONNAME="MY_VERSION"
VERSION="`get_header_version ${HEADER}`"

# --- GIT ---
# tag to tag your release
# and the origin where
ORIGIN=public                        # git repo to push
TAG="${1:-${TAGPREFIX}${VERSION}}"


main()
{
   git_main "${ORIGIN}" "${TAG}" || exit 1
   homebrew_main
}

main "$@"
```

Then make it executable and execute


```
chmod 755 ./bin/release.sh
./bin/release.sh  # sic!
```


