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

#
# convert VfLBochum -> VfL Bochum
# HugoFiege -> Hugo Fiege
#
split_camelcase_string()
{
   # unsightly hacks to a couple of hard to split cases
   sed -e 's/ObjC/Objc/'      | \
   sed -e 's/ObjcOS/ObjcOs /' | \
      sed -e 's/\(.\)\([A-Z]\)\([a-z_0-9]\)/\1 \2\3/g' | \
   sed 's/  / /g'
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


get_project_version()
{
   local filename="$1"
   local versionname="$2"

   local version

   match="`fgrep -s -w "${versionname}" "${filename}" | head -1`"
   case "${match}" in
      *"<<"*)
         echo "${match}" | \
         sed 's|(\([0-9]*\) \<\< [0-9]*)|\1|g' | \
         sed 's|^.*(\(.*\))|\1|' | \
         sed 's/ | /./g'
      ;;

      *)
         # may stumble if there is any other number than version in the line
         version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
         if [ -z "${version}" ]
         then
            version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
            if [ -z "${version}" ]
            then
               version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
            fi
         fi
         echo "$version"
      ;;
   esac
}


# legacy name
get_header_version()
{
   get_project_version "$@"
}


get_versionname_from_project()
{
   echo "$1_VERSION" | split_camelcase_string | make_cpp_string
}


get_language_from_directoryname()
{
   local directory="$1"

   case "${directory}" in
      [a-z-_0-9]*)
         echo "c"
      ;;

      *)
         echo "objc"
      ;;
   esac
}


get_header_from_project()
{
   local project="$1"
   local language="$2"

   case "${language}" in
      c)
         project="`echo "${project}" | split_camelcase_string`"
         echo "src/${project}.h" | make_file_string
      ;;

      *|"")
         echo "src/${project}.h"
      ;;
   esac
}


get_formula_name_from_project()
{
   local project="$1"
   local language="$2"

   language="`tr '[A-Z]' '[a-z]' <<< "${language}"`"
   case "${language}" in
      c|sh|bash)
         echo "${project}" | split_camelcase_string | make_directory_string
      ;;

      *|"")
         echo "${project}" # lowercase ?
      ;;
   esac
}


version_initialize()
{
   local directory

   if [ -z "${MULLE_EXECUTABLE_PID}" ]
   then
      MULLE_EXECUTABLE_PID=$$

      if [ -z "${DEFAULT_IFS}" ]
      then
         DEFAULT_IFS="${IFS}"
      fi

      directory="`mulle-bootstrap library-path 2> /dev/null`"
      [ ! -d "${directory}" ] && echo "failed to locate mulle-bootstrap library" >&2 && exit 1
      PATH="${directory}:$PATH"

      [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh
   fi
}

version_initialize

:
