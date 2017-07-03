#! /usr/bin/env bash

#
# do basic version check
#
if ! homebrew_is_compatible_version "${INSTALLED_MULLE_HOMEBREW_VERSION}" "${MULLE_HOMEBREW_VERSION}"
then
   fail "Installed mulle-homebrew version ${INSTALLED_MULLE_HOMEBREW_VERSION} is \
not compatible with this script from version ${MULLE_HOMEBREW_VERSION}"
fi

# parse options
homebrew_parse_options "$@"

#
# dial past options now as they have been parsed
#
while [ $# -ne 0 ]
do
   case "$1" in
      -*)
         shift
      ;;

      --*)
         shift
         shift
      ;;

      *)
         break;
      ;;
   esac
done


# --- COMMON ---

#
# NAME can usually be deduced, if you follow the conventions
#
if [ -z "${NAME}" ]
then
   NAME="`get_formula_name_from_project "${PROJECT}" "${LANGUAGE}"`" || exit 1
fi

#
# Use mulle-homebrew-version to determine version
#
if [ -z "${VERSION}" ]
then
   options="--no-info"
   [ ! -z "${LANGUAGE}" ]    && options="${options} --language \"${LANGUAGE}\""
   [ ! -z "${VERSIONNAME}" ] && options="${options} --versionname \"${VERSIONNAME}\""
   [ ! -z "${VERSIONFILE}" ] && options="${options} --versionfile \"${VERSIONFILE}\""

   VERSION="`eval mulle-homebrew-version ${options} "${PROJECT}"`" || exit 1
fi


# --- FORMULA  ---


# dependencies can be empty
if [ -z "${DEPENDENCIES}" -a -f  .DEPENDENCIES ]
then
   log_verbose "Read DEPENDENCIES from \".DEPENDENCIES\""
   DEPENDENCIES="`egrep -v '^#' .DEPENDENCIES`"
fi

BOOTSTRAP_TAP="${BOOTSTRAP_TAP:-mulle-kybernetik/software/}"
case "${BOOTSTRAP_TAP}" in
   */)
   ;;

   *)
      BOOTSTRAP_TAP="${BOOTSTRAP_TAP}/"
   ;;
esac

DEPENDENCY_TAP="${DEPENDENCY_TAP:-${PUBLISHER_TAP}}"
case "${DEPENDENCY_TAP}" in
   */)
   ;;

   *)
      DEPENDENCY_TAP="${DEPENDENCY_TAP}/"
   ;;
esac


# where homebrew grabs the archive off
ARCHIVE_URL="${ARCHIVE_URL:-https://github.com/${PUBLISHER}/${PROJECT}/archive/${VERSION}.tar.gz}"

# written into formula for homebrew, will be evaled
HOMEPAGE_URL="${HOMEPAGE_URL:-https://github.com/${PUBLISHER}/${PROJECT}}"


# --- HOMEBREW TAP ---

#
# Specify to where and under what name to publish via your brew tap
#
# require PUBLISHER (and PUBLISHER_TAP) as command line parameter, so
# that forks don't have to edit this constantly
#
#
TAPS_LOCATION="${TAPS_LOCATION:-..}"

if [ ! -z "${PUBLISHER_TAP}" ]
then
   tmp="`basename -- ${PUBLISHER_TAP}`"
fi

HOMEBREW_TAP="${HOMEBREW_TAP:-${TAPS_LOCATION}/homebrew-${tmp}}"

RBFILE="${RBFILE:-${NAME}.rb}"


# --- GIT ---

if [ -z "${VERSION}" ]
then
   fail "Could not figure out the version. (hint: use VERSIONNAME, VERSIONFILE)"
fi

# tag to tag your release
TAG="${TAG:-${TAG_PREFIX}${VERSION}}"

# git remote to push to, usually origin
ORIGIN="${ORIGIN:-origin}"

# git remote to push to, usually github, can be empty
GITHUB="${GITHUB:-github}"

# git branch to release to, source is always current
BRANCH="${BRANCH:-release}"

