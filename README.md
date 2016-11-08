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

Install into local project `./bin` directory using [mulle-build](//github.com/mulle-nat/mulle-build):

```
echo "https://github.com/mulle-objc/mulle-homebrew;bin/mulle-homebrew" >> .bootstrap/embedded_repositories
mulle-build
```

Copy `bin/mulle-homebrew/repository-info.sh.template` to `bin/repository-info.sh`
and edit it to fit your repository setup:

```
#! /bin/sh

ORIGIN=origin
REMOTEROOTDIR="mulle-objc"
#
# keep these settings for github
#
REMOTEHOST="https://github.com"
REMOTEURL="${REMOTEHOST}/${REMOTEROOTDIR}"
ARCHIVEURL='${REMOTEURL}/${NAME}/archive/${VERSION}.tar.gz'  # ARCHIVEURL will be evaled later! keep it in single quotes

:  # keep! important
```

Copy `bin/mulle-homebrew/release.sh.template` to `bin/release.sh`. Then edit it
to fit your project setup:


```
PROJECT="MyProject"      # your project name, requires camel-case
DESC="MyProject does this and that"
DEPENDENCIES="libz
cmake"                   # list brew dependencies
LANGUAGE=c               # c,cpp, objc of the header file

#
# Ideally you don't hafta change anything below this line
#
MULLE_BOOTSTRAP_FAIL_PREFIX="release.sh"

. ./bin/repository-info.sh || exit 1
. ./bin/mulle-homebrew/mulle-homebrew.sh || exit 1

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


#
# these can usually be deduced, if you follow the conventions
#
NAME="`get_name_from_project "${PROJECT}" "${LANGUAGE}"`"
HEADER="`get_header_from_name "${NAME}"`"
VERSIONNAME="`get_versionname_from_project "${PROJECT}"`"
VERSION="`get_header_version "${HEADER}" "${VERSIONNAME}"`"



# --- HOMEBREW FORMULA ---
# Information needed to construct a proper brew formula
#
HOMEPAGE="${REMOTEURL}/${NAME}"


# --- HOMEBREW TAP ---
# Specify to where and under what name to publish via your brew tap
#
RBFILE="${NAME}.rb"                    # ruby file for brew
HOMEBREWTAP="../homebrew-software"     # your tap repository path


# --- GIT ---
# tag to tag your release
# and the origin where
TAG="${1:-${TAGPREFIX}${VERSION}}"


main()
{
   git_main "${ORIGIN}" "${TAG}" || exit 1
   homebrew_main
}

main "$@"
```

Then make it executable and execute it from your project root


```
chmod 755 ./bin/release.sh
./bin/release.sh  # sic!
```


