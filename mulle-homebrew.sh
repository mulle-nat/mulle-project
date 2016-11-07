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

   [ -z "${version}" ] && exit 1
   [ -z "${archiveurl}" ] && exit 1

   local tmparchive

   tmparchive="/tmp/${name}-${version}-archive"

   if [ ! -f "${tmparchive}" ]
   then
      exekutor curl -L -o "${tmparchive}" "${archiveurl}"
      if [ -z "${MULLE_EXECUTOR_DRY_RUN}" ]
      then
         if [ $? -ne 0 -o ! -f "${tmparchive}"  ]
         then
            echo "Download failed" >&2
            exit 1
         fi
      fi
   else
      echo "using cached file ${tmparchive} instead of downloading again" >&2
   fi

   #
   # anything less than 17 KB is wrong
   #
   size="`exekutor du -k "${tmparchive}" | exekutor awk '{ print $ 1}'`"
   if [ -z "${MULLE_EXECUTOR_DRY_RUN}" ]
   then
      if [ "$size" -lt 17 ]
      then
         echo "Archive truncated or missing" >&2
         cat "${tmparchive}" >&2
         rm "${tmparchive}"
         exit 1
      fi
   fi

   local hash

   hash="`exekutor shasum -p -a 256 "${tmparchive}" | exekutor awk '{ print $1 }'`"

   exekutor cat <<EOF
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
      exekutor echo "   depends_on '${dependency}'"
      shift
   done
   IFS="${DEFAULT_IFS}"

   exekutor cat <<EOF
   depends_on 'mulle-build' => :build

   def install
      system "mulle-install", "-e", "--prefix", "#{prefix}"
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

      *)
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
# ORIGIN
# TAG
#
_git_main()
{
   local origin
   local tag

   origin="${1:-origin}"
   shift
   tag="$1"
   shift

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

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi

   local rval

   _git_main "$@" "$branch"
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
   if [ -z "${MULLE_EXECUTOR_DRY_RUN}" ]
   then
      redirect_exekutor "${HOMEBREWTAP}/${RBFILE}" \
         generate_brew_formula "${PROJECT}" \
                               "${NAME}" \
                               "${HOMEPAGE}" \
                               "${DESC}" \
                               "${VERSION}" \
                               "${ARCHIVEURL}" \
                               "${DEPENDENCIES}" || exit 1
      else
         generate_brew_formula "${PROJECT}" \
                               "${NAME}" \
                               "${HOMEPAGE}" \
                               "${DESC}" \
                               "${VERSION}" \
                               "${ARCHIVEURL}" \
                               "${DEPENDENCIES}" || exit 1
   fi

   log_info "Push brew fomula to tap"
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
            MULLE_BOOTSTRAP_VERBOSE="YES"
         ;;

         -vv)
            GITFLAGS="`concat "${GITFLAGS}" "-v"`"
            MULLE_BOOTSTRAP_FLUFF="YES"
            MULLE_BOOTSTRAP_VERBOSE="YES"
            MULLE_EXECUTOR_TRACE="YES"
         ;;

         -vvv)
            GITFLAGS="`concat "${GITFLAGS}" "-v"`"
            MULLE_TEST_TRACE_LOOKUP="YES"
            MULLE_BOOTSTRAP_FLUFF="YES"
            MULLE_BOOTSTRAP_VERBOSE="YES"
            MULLE_EXECUTOR_TRACE="YES"
         ;;

         -n)
            MULLE_EXECUTOR_DRY_RUN="YES"
         ;;

         -f)
            MULLE_TEST_IGNORE_FAILURE="YES"
         ;;

         -s|--silent)
            MULLE_BOOTSTRAP_TERSE="YES"
         ;;

         -t|--trace)
            set -x
         ;;

         -n|--dry-run)
            MULLE_EXECUTOR_DRY_RUN="YES"
         ;;

         -te|--trace-execution)
            MULLE_EXECUTOR_TRACE="YES"
         ;;

         -*)
            log_error "unknown option \"$1\""
         ;;
      esac

      shift
   done
}


homebrew_initialize()
{
   local directory

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

