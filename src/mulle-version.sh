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
   sed -e 's/ObjC/Objc/'        | \
   sed -e 's/ObjcOS/ObjcOs /'   | \
   sed -e 's/ObjcKVC/ObjcKvc /' | \
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
   log_entry "get_project_version" "$@"

   local filename="$1"
   local versionname="$2"
   local printtype="${3:-NO}"

   local version

   if [ ! -f "${filename}" ]
   then
      log_verbose "\"${filename}\" does not exist"
      return 1
   fi

   match="`fgrep -s -w "${versionname}" "${filename}" | head -1`"
   case "${match}" in
      *"<<"*)
         if [ "${printtype}" = "YES" ]
         then
            echo "<<"
            return 0
         fi

         echo "${match}" | \
         sed -e 's|( *\([0-9]* *\) *<< *[0-9]* *)|\1|g' | \
         sed -e 's|^.*(\(.*\))|\1|' | \
         sed -e 's/ *| */./g'
      ;;

      "")
         log_verbose "No \"${versionname}\" found in \"${filename}\""
         return 1
      ;;

      *)
         # may stumble if there is any other number than version in the line
         version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
         if [ -z "${version}" ]
         then
            if [ "${printtype}" = "YES" ]
            then
               return 1
            fi

            version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
            if [ -z "${version}" ]
            then
               version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
            fi
         fi

         if [ "${printtype}" = "YES" ]
         then
            echo "1.2.3"
            return 0
         fi

         echo "$version"
      ;;
   esac
}


# legacy name
get_header_version()
{
   log_entry "get_header_version" "$@"

   get_project_version "$@"
}


get_versionname_from_project()
{
   log_entry "get_versionname_from_project" "$@"

   echo "$1_VERSION" | split_camelcase_string | make_cpp_string
}


get_language_from_directoryname()
{
   log_entry "get_language_from_directoryname" "$@"

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
   log_entry "get_header_from_project" "$@"

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
   log_entry "get_formula_name_from_project" "$@"

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


project_version_add()
{
   log_entry "project_version_add" "$@"

   local version="$1"
   local add_major="$2"
   local add_minor="$3"
   local add_patch="$4"
   local first_minor="${5:-0}"
   local first_patch="${6:-0}"

   local major
   local minor
   local patch

   major="`cut -d'.' -f 1 <<< "${version}"`"
   major="${major:-0}"
   minor="`cut -d'.' -f 2 <<< "${version}"`"
   minor="${minor:-0}"
   patch="`cut -d'.' -f 3 <<< "${version}"`"
   patch="${patch:-0}"

   if [ "${add_major}" -ne 0 ]
   then
      major="$(expr $major + $add_major)" ||
         fail "wrong increment parameter \"${add_major}\" for major \"${major}\""
      minor="${first_minor}"
      patch="${first_patch}"
   else
      if [ "${add_minor}" -ne 0  ]
      then
         minor="$(expr $minor + $add_minor)" ||
            fail "wrong increment parameter \"${add_minor}\""
         patch="${first_patch}"
      else
         if [ "${add_patch}" -ne 0  ]
         then
            patch="$(expr $patch + $add_patch)" ||
               fail "wrong increment parameter \"${add_patch}\""
         else
            fail "Version would not change"
         fi
      fi
   fi

   if [ "${major}" -ge 4096 ]
   then
      fail "major field is exhausted. Start a new project."
   fi

   if [ "${minor}" -ge 4096 ]
   then
      fail "minor field is exhausted. Update the major."
   fi

   if [ "${patch}" -ge 256 ]
   then
      fail "patch field is exhausted. Update the minor"
   fi

   echo "${major}.${minor}.${patch}"
}


#   local major
#   local minor
#   local patch
#
#   get_major_minor_patch "${version}"
#
get_major_minor_patch()
{
   log_entry "get_major_minor_patch" "$@"

   local version="$1"

   major="`cut -d'.' -f 1 <<< "${version}"`"
   minor="`cut -d'.' -f 2 <<< "${version}"`"
   patch="`cut -d'.' -f 3 <<< "${version}"`"

   [ -z "${major}" -o -z "${minor}" -o -z "${patch}" ] &&
      fail "version is like \"${version}\", but must be like 1.5.0 (major.minor.patch)"
}


set_project_version()
{
   log_entry "set_project_version" "$@"

   local version="$1"
   local versionfile="$2"
   local versionname="$3"

   if [ -z "${versionname}" ]
   then
      redirect_exekutor "${versionfile}" echo "$version"
      return
   fi

   local major
   local minor
   local patch

   get_major_minor_patch "${version}"

   # not lenient for setting at all!
   # // ((0 << 20) | (4 << 8) | 9)
   # // or 0.4.9

   local value
   local scheme

   scheme="`get_project_version "${versionfile}" "${versionname}" "YES"`"

   case "${scheme}" in
      "<<")
         value="(($major << 20) \| ($minor << 8) \| $patch)"

         inplace_sed -e 's|^\(.*\)'"${versionname}"'\([^0-9()]*\)( *( *[0-9][0-9]* *<< *20 *) *\| *( *[0-9][0-9]* *<< *8 *) *\| *[0-9][0-9]* *)\(.*\)$|\1'"${versionname}"'\2'"${value}"'\3|' "${versionfile}" || fail "could not set version number"
      ;;

      "1.2.3")
         value="$major.$minor.$patch"
         inplace_sed -e 's|^\(.*\)'"${versionname}"'\([^0-9]*\)[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\(.*\)$|\1'"${versionname}"'\2'"${value}"'\3|' "${versionfile}" || fail "could not set version number"
      ;;

      *)
         fail "Incompatible versions scheme in \"${versionfile}\". Use either 1.2.3 or ((1 << 20) | (2 << 8) | 3)"
      ;;
   esac
}

