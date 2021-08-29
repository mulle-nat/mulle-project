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

get_class_from_name()
{
   log_entry "get_class_from_name" "$@"

   local name="$1"

   local formula

   ## formula is dervied from name, which is rbfile w/o extension

   formula="$(tr '-' ' ' <<< "${name}")"

   (

      local i
      local tmp
      local result

      IFS=" "
      for i in $formula
      do
         if [ ! -z "$i" ]
         then
            tmp="$(tr '[A-Z]' '[a-z]' <<< "${i}")"
            tmp="$(tr '[a-z]' '[A-Z]' <<< "${tmp:0:1}")${tmp:1}"
            result="${result}${tmp}"
         fi
      done
      printf "%s\n" "${result}"
   )
}


generate_brew_formula_header()
{
   log_entry "generate_brew_formula_header" "$@"

   local project="$1"
   local name="$2"
   local version="$3"
   local homepage="$4"
   local desc="$5"
   local archiveurl="$6"
   local tag="$7"

   [ -z "${version}" ]    && internal_fail "empty version"
   [ -z "${archiveurl}" ] && internal_fail "empty archiveurl"
   [ -z "${tag}" ]        && internal_fail "empty tag"
   local tmparchive

   tmparchive="/tmp/${project}-${tag}-archive"

   if [ "${USE_CACHE}" = 'NO' -a -f "${tmparchive}" ]
   then
      exekutor rm "${tmparchive}" || fail "could not delete old \"${tmparchive}\""
   fi

   if [ ! -f "${tmparchive}" ]
   then
      log_verbose "Downloading \"${archiveurl}\" to \"${tmparchive}\"..."

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
   size="`exekutor du -k "${tmparchive}" | exekutor awk '{ print $1 }'`"
   if [ -z "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" ]
   then
      if [ "$size" -lt "${ARCHIVE_MINSIZE:-2}" ]
      then
         echo "Archive truncated or missing" >&2
         cat "${tmparchive}" >&2
         rm "${tmparchive}"
         exit 1
      fi
   fi

   local hash

   hash="`exekutor shasum -a 256 "${tmparchive}" | exekutor awk '{ print $1 }'`" || exit 1
   log_verbose "Calculated shasum256 \"${hash}\" for \"${tmparchive}\"."

   local formula

   formula="`get_class_from_name "${name}"`"

   ##
   ##

   local lines

   lines="`cat <<EOF
class ${formula} < Formula
${INDENTATION}desc "${desc}"
${INDENTATION}homepage "${homepage}"
${INDENTATION}url "${archiveurl}"
${INDENTATION}sha256 "${hash}"
EOF
`"

   line="version \"${version}\""
   if fgrep -q -s -e "${version}" <<< "${archiveurl}"
   then
      line="# ${line}"
   fi

   lines="${lines}
${INDENTATION}${line}"
   exekutor printf "%s\n" "${lines}"
}


_print_dependencies()
{
   log_entry "_print_dependencies" "$@"

   local dependencies="$1"
   local epilog="$2"

   local lines
   local line

   shell_disable_glob; IFS=$'\n'
   for dependency in ${dependencies}
   do
      shell_enable_glob; IFS="${DEFAULT_IFS}"
      dependency="`eval "echo \"${dependency}\"" `"

      line="${INDENTATION}depends_on \"${dependency}\"${epilog}"

      # initial LF is liked
      lines="${lines}
${line}"
   done

   shell_enable_glob; IFS="${DEFAULT_IFS}"

   if [ ! -z "${lines}" ]
   then
      exekutor printf "%s\n" "${lines}"
   fi
}


generate_brew_formula_dependencies()
{
   log_entry "generate_brew_formula_dependencies" "$@"

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


generate_brew_formula_xcodebuild()
{
   log_entry "generate_brew_formula_xcodebuild" "$@"

   local project="$1"; shift
   local name="$1" ; shift
   local version="$1" ; shift
   local configuration="${1:-Release}" ; [ $# -ne 0 ] && shift

   local aux_args
   local option
   local separator


   for option in "$@"
   do
      aux_args="\"${option}\", ${aux_args}"
      separator=", "
   done

   local lines

   lines="`cat <<EOF

${INDENTATION}def install
${INDENTATION}${INDENTATION}system "xcodebuild", "-configuration", "${configuration}", \
"DSTROOT=#{prefix}", ${aux_args}${separator}"install"
${INDENTATION}end
EOF
`"
   exekutor printf "%s\n" "${lines}"
}


generate_brew_formula_mulle_build()
{
   log_entry "generate_brew_formula_mulle_build" "$@"

   local project="$1"; shift
   local name="$1" ; shift
   local version="$1" ; shift

   local aux_args
   local option

   for option in "$@"
   do
      aux_args=" ,${aux_args}\"${option}\""
   done

   local lines

   lines="`cat <<EOF

${INDENTATION}def install
${INDENTATION}${INDENTATION}system "mulle-install", "-vvv", "--prefix", prefix, "--homebrew"${aux_args}
${INDENTATION}end
EOF
`"
   exekutor printf "%s\n" "${lines}"
}


generate_brew_formula_mulle_test()
{
   log_entry "generate_brew_formula_mulle_test" "$@"

   local project="$1"; shift
   local name="$1" ; shift
   local version="$1" ; shift

   local aux_args
   local option

   for option in "$@"
   do
      aux_args=" ,${aux_args}\"${option}\""
   done

   local lines

   lines="`cat <<EOF

${INDENTATION}test do
${INDENTATION}${INDENTATION}if File.directory? 'test'
${INDENTATION}${INDENTATION}${INDENTATION}system "mulle-test", "-vvv", "--fast-test"
${INDENTATION}${INDENTATION}end
${INDENTATION}end
EOF
`"
   exekutor printf "%s\n" "${lines}"
}


generate_brew_formula_footer()
{
   log_entry "generate_brew_formula_footer" "$@"

   local name="$1"

   local lines

   lines="`cat <<EOF
end
# FORMULA ${name}.rb
EOF
`"
   exekutor printf "%s\n" "${lines}"
}


_generate_brew_formula_build()
{
   log_entry "_generate_brew_formula_build" "$@"

   local project="$1"
   local name="$2"
   local version="$3"

   generate_brew_formula_mulle_build "${project}" "${name}" "${version}"
   generate_brew_formula_mulle_test  "${project}" "${name}" "${version}"
}


_generate_brew_formula()
{
   log_entry "_generate_brew_formula" "$@"

   local project="$1"
   local name="$2"
   local version="$3"
   local dependencies="$4"
   local builddependencies="$5"
   local homepage="$6"
   local desc="$7"
   local archiveurl="$8"
   local tag="$9"

   local generator

   generator=_generate_brew_formula_build
   if shell_is_function "generate_brew_formula_build"
   then
      generator="generate_brew_formula_build"
   fi


   generate_brew_formula_header "${project}" "${name}" "${version}" \
                                "${homepage}" "${desc}" "${archiveurl}" "${tag}" &&
   generate_brew_formula_dependencies "${dependencies}" "${builddependencies}" &&
   ${generator} "${project}" "${name}" "${version}" "${dependencies}" &&
   generate_brew_formula_footer "${name}"
}


formula_push()
{
   log_entry "formula_push" "$@"

   local rbfile="$1" ; shift
   local version="$1" ; shift
   local name="$1" ; shift
   local homebrewtap="$1" ; shift
   local tag="$1"; shift

   HOMEBREW_TAP_BRANCH="${HOMEBREW_TAP_BRANCH:-${GIT_DEFAULT_BRANCH:-master}}"
   HOMEBREW_TAP_REMOTE="${HOMEBREW_TAP_REMOTE:-origin}"

   #
   # this may fail if the formula didn't change (during untag/tag)
   # cycle
   #
   local verb

   verb="${tag##*-}"
   verb="${verb:-release}"
   tag="${tag%-*}"

   log_info "Push brew formula \"${rbfile}\" to \"${HOMEBREW_TAP_REMOTE}\""
   (
      exekutor cd "${homebrewtap}" &&
      exekutor git add "${rbfile}" &&
      exekutor git commit -m "${tag} ${verb} of ${name}" "${rbfile}"
      exekutor git push "${HOMEBREW_TAP_REMOTE}" "${HOMEBREW_TAP_BRANCH}"
   )
   :
}


homebrew_push()
{
   log_entry "homebrew_push" "$@"

   local name="$1"; shift
   local version="$1"; shift
   local homebrewtap="$1"; shift
   local rbfile="$1"; shift
   local tag="$1"; shift

   local formula

   [ -z "${name}" ]        && internal_fail "missing name"
   [ -z "${version}" ]     && internal_fail "missing version"
   [ -z "${homebrewtap}" ] && internal_fail "missing homebrewtap"
   [ -z "${rbfile}" ]      && internal_fail "missing rbfile"
   [ -z "${tag}" ]         && internal_fail "missing tag"

   [ ! -d "${homebrewtap}" ] && fail "Failed to locate tap directory \"${homebrewtap}\" from \"$PWD\""

   log_info "Push brew formula \"${homebrewtap}/${rbfile}\""

   formula_push "${rbfile}" "${version}" "${name}" "${homebrewtap}" "${tag}"
}


homebrew_generate()
{
   log_entry "homebrew_generate" "$@"

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
   local tag="$1"; shift

   local formula
# DESC must not be empty
   [ -z "${desc}" ]  && fail "DESC is empty"

   [ -z "${project}" ]     && internal_fail "missing project"
   [ -z "${name}" ]        && internal_fail "missing name"
   [ -z "${version}" ]     && internal_fail "missing version"
   [ -z "${homepage}" ]    && internal_fail "missing homepage"
   [ -z "${archiveurl}" ]  && internal_fail "missing archiveurl"
   [ -z "${homebrewtap}" ] && internal_fail "missing homebrewtap"
   [ -z "${rbfile}" ]      && internal_fail "missing rbfile"
   [ -z "${tag}" ]         && internal_fail "missing tag"


   [ ! -d "${homebrewtap}" ] && fail "Failed to locate tap directory \"${homebrewtap}\" from \"$PWD\""

   log_info "Generate brew formula \"${homebrewtap}/${rbfile}\""

   log_fluff "project           = ${C_RESET}${project}"
   log_fluff "name              = ${C_RESET}${name}"
   log_fluff "version           = ${C_RESET}${version}"
   log_fluff "homepage          = ${C_RESET}${homepage}"
   log_fluff "desc              = ${C_RESET}${desc}"
   log_fluff "archiveurl        = ${C_RESET}${archiveurl}"
   log_fluff "dependencies      = ${C_RESET}${dependencies}"
   log_fluff "builddependencies = ${C_RESET}${builddependencies}"
   log_fluff "tag               = ${C_RESET}${tag}"

   local generator

   generator=_generate_brew_formula
   if shell_is_function "generate_brew_formula"
   then
      generator="generate_brew_formula"
   fi

   formula="`${generator} "${project}" \
                          "${name}" \
                          "${version}" \
                          "${dependencies}" \
                          "${builddependencies}" \
                          "${homepage}" \
                          "${desc}" \
                          "${archiveurl}" \
                          "${tag}"`" || exit 1

   if [ "${OPTION_ECHO}" ]
   then
      printf "%s\n" "${formula}"
      return
   fi

   redirect_exekutor "${homebrewtap}/${rbfile}" printf "%s\n" "${formula}"
}
