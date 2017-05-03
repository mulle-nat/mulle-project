#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#

generate_brew_formula_header()
{
   local project="$1"
   local name="$2"
   local version="$3"
   local homepage="$4"
   local desc="$5"
   local archiveurl="$6"

   [ -z "${version}" ]    && internal_fail "empty version"
   [ -z "${archiveurl}" ] && internal_fail "empty archiveurl"

   local tmparchive

   tmparchive="/tmp/${name}-${version}-archive"

   if [ -z "${USE_CACHE}" -a -f "${tmparchive}" ]
   then
      exekutor rm "${tmparchive}" || fail "could not delete old \"${tmparchive}\""
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

   local lines

   ##
   ##

   lines="`cat <<EOF
class ${project} < Formula
   homepage "${homepage}"
   desc "${desc}"
   url "${archiveurl}"
   version "${version}"
   sha256 "${hash}"

EOF
`"
   exekutor echo "${lines}"
}


_print_dependencies()
{
   local dependencies="$1"
   local epilog="$2"

   local lines
   local line

   IFS="
"
   for dependency in ${dependencies}
   do
      IFS="${DEFAULT_IFS}"
      dependency="`eval echo "${dependency}"`"

      line="   depends_on '${dependency}'${epilog}"

      # initial LF is liked
      lines="${lines}
${line}"
   done
   IFS="${DEFAULT_IFS}"

   if [ ! -z "${lines}" ]
   then
      exekutor echo "${lines}"
   fi
}


generate_brew_formula_dependencies()
{
   local dependencies="$1"
   local builddependencies="$2"

   if [ ! -z "${dependencies}" ]
   then
      _print_dependencies "${dependencies}"
   fi

   if [ ! -z "${builddependencies}" ]
   then
      _print_dependencies "${builddependencies}" " => :build"
   fi
}


generate_brew_formula_mulle_build()
{
   local lines

   lines="`cat <<EOF

   def install
      system "mulle-install", "-vvv", "--prefix", "#{prefix}", "--homebrew"
   end

   test do
      system "mulle-test"
   end
EOF
`"
   exekutor echo "${lines}"
}


generate_brew_formula_footer()
{
   local name="$1"

   local lines

   lines="`cat <<EOF
end
# FORMULA ${name}.rb
EOF
`"
   exekutor echo "${lines}"
}


_generate_brew_formula()
{
   local project="$1"
   local name="$2"
   local version="$3"
   local dependencies="$4"
   local builddependencies="$5"
   local homepage="$6"
   local desc="$7"
   local archiveurl="$8"

   generate_brew_formula_header "${project}" "${name}" "${version}" \
                                "${homepage}" "${desc}" "${archiveurl}" &&
   generate_brew_formula_dependencies "${dependencies}" "${builddependencies}" &&
   generate_brew_formula_build "${project}" "${name}" "${version}" "${dependencies}" &&
   generate_brew_formula_footer "${name}"
}


get_name_from_project()
{
   local name="$1"
   local language="$2"

   case "${language}" in
      c|C|sh|bash)
         echo "${name}" | split_camelcase_string | make_directory_string
      ;;

      ""|*)
         echo "${name}"
      ;;
   esac
}


formula_push()
{
   local rbfile="$1" ; shift
   local version="$1" ; shift
   local name="$1" ; shift
   local homebrewtap="$1" ; shift

   HOMEBREW_TAP_BRANCH="${HOMEBREW_TAP_BRANCH:-master}"
   HOMEBREW_TAP_REMOTE="${HOMEBREW_TAP_REMOTE:-origin}"

   log_info "Push brew fomula \"${rbfile}\" to \"${HOMEBREW_TAP_REMOTE}\""
   (
      exekutor cd "${homebrewtap}" &&
      exekutor git add "${rbfile}" &&
      exekutor git commit -m "${version} release of ${name}" "${rbfile}" &&
      exekutor git push "${HOMEBREW_TAP_REMOTE}" "${HOMEBREW_TAP_BRANCH}"
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

         --homebrew-path)
            [ $# -eq 1 ] && fail "missing parameter for \"$1\""
            shift
            HOMEBREW_PATH="$1"
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


homebrew_main()
{
   local project="$1" ; shift
   local name="$1"; shift
   local version="$1"; shift
   local dependencies="$1"; shift
   local builddependencies="$1"; shift
   local homepage="$1"; shift
   local desc="$1"; shift
   local archiveurl="$1"; shift
   local homebrewtap="$1"; shift
   local rbfile="$1"; shift

   local formula

   [ -z "${project}" ]     && internal_fail "missing project"
   [ -z "${name}" ]        && internal_fail "missing name"
   [ -z "${version}" ]     && internal_fail "missing version"
   [ -z "${homepage}" ]    && internal_fail "missing homepage"
   [ -z "${archiveurl}" ]  && internal_fail "missing archiveurl"
   [ -z "${homebrewtap}" ] && internal_fail "missing homebrewtap"
   [ -z "${rbfile}" ]      && internal_fail "missing rbfile"

   [ ! -d "${homebrewtap}" ] && fail "failed to locate \"${homebrewtap}\" from \"$PWD\""

   log_info "Generate brew fomula \"${homebrewtap}/${rbfile}\""
   formula="`generate_brew_formula "${project}" \
                                   "${name}" \
                                   "${version}" \
                                   "${dependencies}" \
                                   "${builddependencies}" \
                                   "${homepage}" \
                                   "${desc}" \
                                   "${archiveurl}"`" || exit 1

   redirect_exekutor "${homebrewtap}/${rbfile}" echo "${formula}"

   formula_push "${rbfile}" "${version}" "${name}" "${homebrewtap}"
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
