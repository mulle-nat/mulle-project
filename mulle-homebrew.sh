#! /bin/sh
#
#
#

generate_brew_formula()
{
   local project
   local name
   local homepage
   local desc
   local version
   local archiveurl
   local dependencies

   project="$1"
   shift
   name="$1"
   shift
   homepage="$1"
   shift
   desc="$1"
   shift
   version="$1"
   shift
   archiveurl="$1"
   shift
   dependencies="$1"
   shift

   [ -z "${version}" ]    && internal_fail "empty version"
   [ -z "${archiveurl}" ] && internal_fail "empty archiveurl"

   local tmparchive

   tmparchive="/tmp/${name}-${version}-archive"

   if [ -z "${USE_CACHE}" -a -f "${tmparchive}" ]
   then
      rm "${tmparchive}" || fail "could not delete old \"${tmparchive}\""
   fi

   if [ ! -f "${tmparchive}" ]
   then
      exekutor curl -L -o "${tmparchive}" "${archiveurl}"
      if [ -z "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" ]
      then
         if [ $? -ne 0 -o ! -f "${tmparchive}"  ]
         then
            fail "Download failed"
         fi
      fi
   else
      echo "Using cached file \"${tmparchive}\" instead of downloading again" >&2
   fi

   #
   # anything less than 2 KB is wrong
   #
   size="`exekutor du -k "${tmparchive}" | exekutor awk '{ print $ 1}'`"
   if [ -z "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" ]
   then
      if [ "$size" -lt ${ARCHIVE_MINSIZE:-2} ]
      then
         echo "Archive truncated or missing" >&2
         cat "${tmparchive}" >&2
         rm "${tmparchive}"
         exit 1
      fi
   fi

   local hash

   hash="`exekutor shasum -p -a 256 "${tmparchive}" | exekutor awk '{ print $1 }'`"

   cat <<EOF
class ${project} < Formula
   homepage "${homepage}"
   desc "${desc}"
   url "${archiveurl}"
   version "${version}"
   sha256 "${hash}"

EOF

IFS="
"
   for dependency in ${dependencies}
   do
      dependency="`eval echo "${dependency}"`"

      echo "   depends_on '${dependency}'"
      shift
   done
   IFS="${DEFAULT_IFS}"

   cat <<EOF
   depends_on '${BOOTSTRAP_TAP}mulle-build' => :build

   def install
      system "mulle-install", "--prefix", "#{prefix}", "--homebrew"
   end

   test do
      system "mulle-test"
   end
end
# FORMULA ${name}.rb
EOF
}


#
# convert VfLBochum -> VfL Bochum
# HugoFiege -> Hugo Fiege
#
split_camelcase_string()
{
   sed -e 's/\(.\)\([A-Z]\)\([a-z_0-9]\)/\1 \2\3/g'
}

# convert all to uppercase, spaces and minus to '_'
# does not work well for camel case
make_cpp_string()
{
   tr '[a-z]' '[A-Z]' | tr ' ' '_' | tr '-' '_'
}


make_directory_string()
{
   tr '[A-Z]' '[a-z]' | tr ' ' '-' | tr '_' '-'
}


make_file_string()
{
   tr '[A-Z]' '[a-z]' | tr ' ' '_' | tr '-' '_'
}


get_name_from_project()
{
   case "$2" in
      c|C)
         echo "$1" | split_camelcase_string | make_directory_string
      ;;

      ""|*)
         echo "$1"
      ;;
   esac
}


get_header_from_name()
{
   echo "src/$1.h" | make_file_string
}


get_versionname_from_project()
{
   echo "$1_VERSION" | split_camelcase_string | make_cpp_string
}


get_header_version()
{
   local filename
   local versionname

   filename="$1"
   versionname="${2:-${VERSIONNAME}}"  # backwards compatibility

   fgrep -s -w "${versionname}" "${filename}" | \
   sed 's|(\([0-9]*\) \<\< [0-9]*)|\1|g' | \
   sed 's|^.*(\(.*\))|\1|' | \
   sed 's/ | /./g' | \
   head -1
}


git_tag_must_not_exist()
{
   local tag

   tag="$1"

   if git rev-parse "${tag}" > /dev/null 2>&1
   then
      fail "Tag \"${tag}\" already exists"
   fi
}


git_tag_must_not_exist()
{
   local tag

   tag="$1"

   if git rev-parse "${tag}" > /dev/null 2>&1
   then
      fail "Tag \"${tag}\" already exists"
   fi
}


git_must_be_clean()
{
   local name

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      fail "\"${name}\" is not a git repository"
   fi

   local clean

   clean=`git status -s --untracked-files=no`
   if [ "${clean}" != "" ]
   then
      fail "repository \"${name}\" is tainted"
   fi
}


# Parameters!
#
# BRANCH
# ORIGIN
# TAG
#
_git_main()
{
   local branch
   local origin
   local tag

   branch="${1:-master}"
   [ $# -ne 0 ] && shift

   origin="${1:-origin}"
   [ $# -ne 0 ] && shift

   tag="$1"
   [ $# -ne 0 ] && shift

   case "${tag}" in
      -*|"")
         fail "Invalid tag \"${tag}\""
      ;;
   esac

   case "${origin}" in
      -*|"")
         fail "Invalid origin \"${tag}\""
      ;;
   esac

   exekutor git_must_be_clean               || return 1
   exekutor git_tag_must_not_exist "${tag}" || return 1

   #
   # make it a release
   #
   log_info "Push clean state of \"${branch}\" to \"${origin}\""
   exekutor git push "${origin}" "${branch}"  || return 1

   log_info "Make it a release, by rebasing"
   exekutor git checkout -B release           || return 1
   exekutor git rebase "${branch}"            || return 1

   # if rebase fails, we shouldn't be hitting tag now

   log_info "Tag the release with \"${tag}\""
   exekutor git tag "${tag}"                    || return 1

   log_info "Push release with tags to \"${origin}\""
   exekutor git push "${origin}" release --tags || return 1

   log_info "Check if remote github is present"
   exekutor git ls-remote  -q --exit-code github release > /dev/null 2>&1
   if [ $? -eq 0 ]
   then
      log_info "Pushing release with tags to github"
      exekutor git push github release --tags || return 1
   else
      log_info "There is no remote named github"
   fi
}


git_main()
{
   local branch
   local rval

   log_info "Verify repository"

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-master}" # for dry run
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi

   _git_main "${branch}" "$@"
   rval=$?

   log_info "Checkout \"${branch}\" again"
   exekutor git checkout "${branch}" || return 1
   return $rval
}


#
# Expected environment!
# PROJECT
# NAME
# VERSION
# HOMEPAGE
# DESC
# DEPENDENCIES
# HOMEBREWTAP
# RBFILE
#
homebrew_main()
{
   [ ! -d "${HOMEBREWTAP}" ] && fail "failed to locate \"${HOMEBREWTAP}\""

   ARCHIVEURL="`eval echo "${ARCHIVEURL}"`"

   log_info "Generate brew fomula \"${PROJECT}\""
   redirect_exekutor "${HOMEBREWTAP}/${RBFILE}" \
      generate_brew_formula "${PROJECT}" \
                            "${NAME}" \
                            "${HOMEPAGE}" \
                            "${DESC}" \
                            "${VERSION}" \
                            "${ARCHIVEURL}" \
                            "${DEPENDENCIES}" || exit 1

   log_info "Push brew fomula \"${RBFILE}\" to tap"
   (
      exekutor cd "${HOMEBREWTAP}" ;
      exekutor git add "${RBFILE}" ;
      exekutor git commit -m "${VERSION} release of ${NAME}" "${RBFILE}" ;
      exekutor git push origin master
   )  || exit 1
}


#
# the caller won't know how many options have been consumed
#
homebrew_parse_options()
{
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

         --cache)
            USE_CACHE="YES"
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

         --bootstrap-tap)
            [ $# -eq 1 ] && fail "missing parameter"
            shift
            BOOTSTRAP_TAP="$1"
         ;;

         --branch)
            [ $# -eq 1 ] && fail "missing parameter"
            shift
            BRANCH="$1"
         ;;

         --dependency-tap)
            [ $# -eq 1 ] && fail "missing parameter"
            shift
            DEPENDENCY_TAP="$1"
         ;;

         --publisher)
            [ $# -eq 1 ] && fail "missing parameter"
            shift
            PUBLISHER="$1"
         ;;

         --publisher-tap)
            [ $# -eq 1 ] && fail "missing parameter"
            shift
            PUBLISHER_TAP="$1"
         ;;

         --tag)
            [ $# -eq 1 ] && fail "missing parameter"
            shift
            TAG="$1"
         ;;

         -*)
            log_error "unknown option \"$1\""
            exit 1
         ;;
      esac

      shift
   done
}


homebrew_initialize()
{
   local directory

   MULLE_EXECUTABLE_PID=$$

   if [ -z "${DEFAULT_IFS}" ]
   then
      DEFAULT_IFS="${IFS}"
   fi

   directory="`mulle-bootstrap library-path 2> /dev/null`"
   [ ! -d "${directory}" ] && echo "failed to locate mulle-bootstrap library" >&2 && exit 1
   PATH="${directory}:$PATH"

   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ]   && . mulle-bootstrap-logging.sh
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_ARRAY_SH}" ]     && . mulle-bootstrap-array.sh
}

homebrew_initialize

:

