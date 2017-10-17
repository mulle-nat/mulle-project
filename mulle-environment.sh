#! /usr/bin/env bash

#
# the caller won't know how many options have been consumed
#
project_parse_options()
{
   DO_PUSH_FORMULA="YES"
   USE_CACHE="NO"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -v|--verbose)
            GITFLAGS="`concat "${GITFLAGS}" "-v"`"
            MULLE_FLAG_LOG_VERBOSE="YES"
         ;;

         -vv)
            GITFLAGS="`concat "${GITFLAGS}" "-v"`"
            MULLE_FLAG_LOG_FLUFF="YES"
            MULLE_FLAG_LOG_VERBOSE="YES"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
         ;;

         -vvv)
            GITFLAGS="`concat "${GITFLAGS}" "-v"`"
            MULLE_TEST_TRACE_LOOKUP="YES"
            MULLE_FLAG_LOG_FLUFF="YES"
            MULLE_FLAG_LOG_VERBOSE="YES"
            MULLE_FLAG_LOG_EXEKUTOR="YES"
         ;;

         -f)
            MULLE_TEST_IGNORE_FAILURE="YES"
         ;;

         -n|--dry-run)
            MULLE_FLAG_EXEKUTOR_DRY_RUN="YES"
         ;;

         -s|--silent)
            MULLE_FLAG_LOG_TERSE="YES"
         ;;

         -t|--trace)
            set -x
         ;;

         -te|--trace-execution)
            MULLE_FLAG_LOG_EXEKUTOR="YES"
         ;;

         # single arg long (kinda lame)
         --cache)
            USE_CACHE="YES"
         ;;

         --no-cache)
            USE_CACHE="NO"
         ;;

         --echo)
            OPTION_ECHO="YES"
         ;;

         --no-git)
            DO_GIT_RELEASE="NO"
         ;;

         --no-formula)
            DO_GENERATE_FORMULA="NO"
         ;;

         --no-push)
            DO_PUSH_FORMULA="NO"
         ;;

         # arg long

         --bootstrap-tap)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            BOOTSTRAP_TAP="$1"
         ;;

         --branch)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            BRANCH="$1"
         ;;

         --dependency-tap)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            DEPENDENCY_TAP="$1"
         ;;

         --github)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            GITHUB="$1"
         ;;

         --homepage-url)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            HOMEPAGE_URL="$1"
         ;;

         --origin)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            ORIGIN="$1"
         ;;

         --project)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            PROJECT="$1"
         ;;

         --publisher)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            PUBLISHER="$1"
         ;;

         --publisher-tap)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            PUBLISHER_TAP="$1"
         ;;

         --tag)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            TAG="$1"
         ;;

         --tag-prefix)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            TAG_PREFIX="$1"
         ;;

         --taps-location)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            TAPS_LOCATION="$1"
         ;;

            # allow user to specify own parameters for his
            # generate_formula scripts w/o having to modify this file
         --*)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""

            varname="`sed 's/^..//' <<< "$1"`"
            varname="`tr '-' '_' <<< "${varname}"`"
            varname="`tr '[a-z]' '[A-Z]' <<< "${varname}"`"
            if ! egrep -q -s '^[A-Z_][A-Z0-9_]*$' <<< "${varname}" > /dev/null
            then
               fail "invalid variable specification \"${varname}\", created by \"$1\""
            fi

            shift
            eval "${varname}='$1'"
            log_info "User variable ${varname} set to \"$1\""
         ;;

         -*)
            log_error "unknown option \"$1\""
            exit 1
         ;;
      esac

      shift
   done
}


project_is_compatible_version()
{
   local installed="$1"
   local script="$2"

   local s_major
   local s_minor
   local i_major
   local i_minor

   s_major="`echo "${script}"    | head -1 | cut -d. -f1`"
   s_minor="`echo "${script}"    | head -1 | cut -d. -f2`"
   i_major="`echo "${installed}" | head -1 | cut -d. -f1`"
   i_minor="`echo "${installed}" | head -1 | cut -d. -f2`"

   if [ "${i_major}" = "" -o "${i_minor}" = "" -o \
        "${s_major}" = "" -o "${s_minor}" = "" ]
   then
      return 2
   fi

   if [ "${i_major}" != "${s_major}" ]
   then
      return 1
   fi

   if [ "${i_minor}" -lt "${s_minor}" ]
   then
      return 1
   fi

   return 0
}



environment_main()
{
#   if ! project_is_compatible_version "${INSTALLED_MULLE_PROJECT_VERSION}" "${MULLE_PROJECT_VERSION}"
#   then
#      fail "Installed mulle-project version ${INSTALLED_MULLE_PROJECT_VERSION} is \
#not compatible with this script from version ${MULLE_PROJECT_VERSION}"
#   fi

   # parse options
   project_parse_options "$@"

   # --- COMMON ---

   if [ -z "${PROJECT}" ]
   then
      PROJECT="`basename -- "$PWD"`"
   fi

   #
   # NAME can usually be deduced, if you follow the conventions
   #
   if [ -z "${NAME}" ]
   then
      NAME="`get_formula_name_from_project "${PROJECT}" "${LANGUAGE}"`" || exit 1
   fi

   #
   # Use mulle-project-version to determine version
   #
   if [ -z "${VERSION}" ]
   then
      options="--no-info --no-tag-warning"
      [ ! -z "${LANGUAGE}" ]    && options="${options} --language \"${LANGUAGE}\""
      [ ! -z "${VERSIONNAME}" ] && options="${options} --versionname \"${VERSIONNAME}\""
      [ ! -z "${VERSIONFILE}" ] && options="${options} --versionfile \"${VERSIONFILE}\""

      VERSION="`eval mulle-project-version ${options} "${PROJECT}"`" || exit 1
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


   # where to grab the archive off
   ARCHIVE_URL="${ARCHIVE_URL:-https://github.com/${PUBLISHER}/${PROJECT}/archive/${VERSION}.tar.gz}"

   # written into formula for project, will be evaled
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
}

environment_main "$@"

:
