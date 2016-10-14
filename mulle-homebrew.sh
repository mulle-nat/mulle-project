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
      if [ $? -ne 0 -o ! -f "${tmparchive}" ]
      then
         echo "Download failed" >&2
         exit 1
      fi
   else
      echo "using cached file ${tmparchive} instead of downloading again" >&2
   fi

   #
   # anything less than 17 KB is wrong
   #
   size="`exekutor du -k "${tmparchive}" | exekutor awk '{ print $ 1}'`"
   if [ $size -lt 17 ]
   then
      echo "Archive truncated or missing" >&2
      cat "${tmparchive}" >&2
      rm "${tmparchive}"
      exit 1
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


get_header_version()
{
   local filename

   filename="$1"
   fgrep "${VERSIONNAME}" "${filename}" | \
   sed 's|(\([0-9]*\) \<\< [0-9]*)|\1|g' | \
   sed 's|^.*(\(.*\))|\1|' | \
   sed 's/ | /./g'
}


git_must_be_clean()
{
   local name
   local clean

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      fail "\"${name}\" is not a git repository"
   fi

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

   origin="$1"
   shift
   tag="$1"
   shift



   exekutor git_must_be_clean || return 1

   #
   # make it a release
   #
   exekutor git checkout -B release  || return 1

   exekutor git rebase "${branch}"   || return 1

   # if rebase fails, we shouldn't be hitting tag now
   exekutor git tag "${tag}"         || return 1
   exekutor git push "${origin}" release --tags  || return 1

   executor git ls-remote github 2> /dev/null
   if [ $? -eq 0 ]
   then
      log_fluff "Pushing to github"
      exekutor git push github release --tags || return 1
   else
      log_verbose "There is no remote named github"
   fi

   exekutor git checkout "${branch}"          || return 1
   exekutor git push "${origin}" "${branch}"  || return 1
}


git_main()
{
   local branch

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi

   if _git_main "$@" "$branch"
   then
      return 0
   fi

   exekutor git checkout "${branch}"
   exit 1
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

   redirect_exekutor "${HOMEBREWTAP}/${RBFILE}" \
      generate_brew_formula "${PROJECT}" \
                            "${NAME}" \
                            "${HOMEPAGE}" \
                            "${DESC}" \
                            "${VERSION}" \
                            "${ARCHIVEURL}" \
                            "${DEPENDENCIES}" || exit 1
   (
      exekutor cd "${HOMEBREWTAP}" ;
      exekutor git add "${RBFILE}" ;
      exekutor git commit -m "${VERSION} release of ${NAME}" "${RBFILE}" ;
      exekutor git push origin master
   )  || exit 1
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

   . "mulle-bootstrap-logging.sh"
   . "mulle-bootstrap-functions.sh"
}

homebrew_initialize

