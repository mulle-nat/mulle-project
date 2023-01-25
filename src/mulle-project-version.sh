# shellcheck shell=bash
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
project::version::split_camelcase_string()
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
project::version::make_cpp_string()
{
   tr '[:lower:]' '[:upper:]' | tr ' ' '_' | tr '-' '_'
}


project::version::make_directory_string()
{
   tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-'
}


project::version::make_file_string_no_hyphen()
{
   tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_'
}


project::version::make_file_string()
{
   tr '[:upper:]' '[:lower:]' | tr ' ' '_'
}


project::version::get_project_version()
{
   log_entry "project::version::get_project_version" "$@"

   local filename="$1"
   local versionname="$2"
   local versioncustom="${3:-NO}"
   local printtype="${4:-NO}"

   local version

   if [ ! -f "${filename}" ]
   then
      log_verbose "\"${filename}\" does not exist"
      return 1
   fi

   match="`grep -F -s -w "${versionname}" "${filename}" | head -2`"
   # get rid of an ifdef
   match="`grep -E -v '^#if' <<< "${match}" | head -1`"

   if [ -z "${match}" ]
   then
      match="`grep -E -v '^#' "${filename}" | head -1`"
   fi

   log_debug "match=${match}"

   case "${match}" in
      *"<<"*)
         if [ "${printtype}" = 'YES' ]
         then
            echo "<<"
            return 0
         fi

         printf "%s\n" "${match}" | \
         sed -e 's|( *\([0-9]* *\) *<< *[0-9]* *)|\1|g' | \
         sed -e 's|^.*(\(.*\))|\1|' | \
         sed -e 's/ *| */./g' |
         sed -e 's/ *$//'
      ;;

      "")
         log_verbose "No \"${versionname}\" found in \"${filename}\""
         return 1
      ;;

      *)
         # this is the default, that we always print
         if [ "${printtype}" = 'YES' ]
         then
            if [ "${versioncustom}" = 'YES' ]
            then
               echo "1.2.3.4"
            else
               echo "1.2.3"
            fi
            return 0
         fi

         # may stumble if there is any other number than version in the line
         version=""
         if [ "${versioncustom}" = 'YES' ]
         then
            version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
         fi

         if [ -z "${version}" ]
         then
            version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
            if [ -z "${version}" ]
            then
               if [ "${printtype}" = 'YES' ]
               then
                  return 1
               fi

               version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
               if [ -z "${version}" ]
               then
                  version="`sed -n 's/^[^0-9]*\([0-9][0-9]*\).*$/\1/p' <<< "${match}"`"
               fi
            fi
         fi

         printf "%s\n" "$version"
      ;;
   esac

   log_debug "version=${version}"
}


# legacy name
project::version::get_header_version()
{
   log_entry "project::version::get_header_version" "$@"

   project::version::get_project_version "$@"
}


project::version::get_language_from_directoryname()
{
   log_entry "project::version::get_language_from_directoryname" "$@"

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


project::version::get_header_from_project()
{
   log_entry "project::version::get_header_from_project" "$@"

   local project="$1"
   local language="$2"

   local filename

   case "${language}" in
      c)
         project="`printf "%s\n" "${project}" | project::version::split_camelcase_string`"

         filename="${filename}-version"
         if [ -f "${filename}.h" ]
         then
            printf "%s\n" "${filename}.h"
            return
         fi

         filename="src/${project}-version"
         if [ -f "${filename}.h" ]
         then
            printf "%s\n" "${filename}.h"
            return
         fi

         filename="`project::version::make_file_string_no_hyphen <<< "src/${project}"`"
         if [ -f "${filename}.h" ]
         then
            printf "%s\n" "${filename}.h"
            return
         fi

         project::version::make_file_string <<< "src/${project}.h"
      ;;

      *|"")
         echo "src/${project}.h"
      ;;
   esac
}


project::version::get_formula_name_from_project()
{
   log_entry "project::version::get_formula_name_from_project" "$@"

   local project="$1"
   local language="$2"

   language="`tr '[:upper:]' '[:lower:]' <<< "${language}"`"
   case "${language}" in
      c|sh|bash)
         printf "%s\n" "${project}" \
         | project::version::split_camelcase_string \
         | project::version::make_directory_string
      ;;

      *|"")
         printf "%s\n" "${project}" # lowercase ?
      ;;
   esac
}


project::version::add()
{
   log_entry "project::version::add" "$@"

   local version="$1"
   local add_major="$2"
   local add_minor="$3"
   local add_patch="$4"
   local add_custom="$5"
   local first_minor="${6:-0}"
   local first_patch="${7:-0}"
   local first_custom="${8:-0}"

   local major
   local minor
   local patch

   major="`cut -d'.' -f 1 <<< "${version}"`"
   major="${major:-0}"
   minor="`cut -d'.' -f 2 <<< "${version}"`"
   minor="${minor:-0}"
   patch="`cut -d'.' -f 3 <<< "${version}"`"
   patch="${patch:-0}"
   custom="`cut -d'.' -f 4 <<< "${version}"`"
   custom="${custom:-0}"

   if [ "${add_major}" -ne 0 ]
   then
      major="$(expr $major + $add_major)" ||
         fail "wrong increment parameter \"${add_major}\" for major \"${major}\""
      minor="${first_minor}"
      patch="${first_patch}"
      custom="${first_custom}"
   else
      if [ "${add_minor}" -ne 0  ]
      then
         minor="$(expr $minor + $add_minor)" ||
            fail "wrong increment parameter \"${add_minor}\""
         patch="${first_patch}"
         custom="${first_custom}"
      else
         if [ "${add_patch}" -ne 0  ]
         then
            patch="$(expr $patch + $add_patch)" ||
               fail "wrong increment parameter \"${add_patch}\""
            custom="${first_custom}"
         else
            if [ "${add_custom}" -ne 0  ]
            then
               custom="$(expr $custom + $add_custom)" ||
                  fail "wrong increment parameter \"${add_custom}\""
            else
               fail "Version would not change"
            fi
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


   if [ "${custom}" -ge 4096 ]
   then
      fail "custom field is exhausted. Update the major."
   fi

   case "${version}" in
      *\.*\.*\.*)
         printf "%s\n" "${major}.${minor}.${patch}.${custom}"
      ;;

      *)
         printf "%s\n" "${major}.${minor}.${patch}"
      ;;
   esac
}


#   local major
#   local minor
#   local patch
#   local custom , optional
#
#   get_major_minor_patch "${version}"
#
project::version::get_major_minor_patch_custom()
{
   log_entry "project::version::get_major_minor_patch_custom" "$@"

   local version="$1"

   major="`cut -d'.' -f 1 <<< "${version}"`"
   minor="`cut -d'.' -f 2 <<< "${version}"`"
   patch="`cut -d'.' -f 3 <<< "${version}"`"
   custom="`cut -d'.' -f 4 <<< "${version}"`"

   [ -z "${major}" -o -z "${minor}" -o -z "${patch}" ] &&
      fail "version is like \"${version}\", but must be like 1.5.0 (major.minor.patch)"
}


project::version::set()
{
   log_entry "project::version::set" "$@"

   local version="$1"
   local versionfile="$2"
   local versionname="$3"
   local versioncustom="${4:-NO}"

   if [ -z "${versionname}" ]
   then
      redirect_exekutor "${versionfile}" printf "%s\n" "$version"
      return
   fi

   local major
   local minor
   local patch
   local custom

   project::version::get_major_minor_patch_custom "${version}"

   # not lenient for setting at all!
   # // ((0 << 20) | (4 << 8) | 9)
   # // or 0.4.9

   local value
   local scheme

   scheme="`project::version::get_project_version "${versionfile}" "${versionname}" "${versioncustom}" 'YES'`"

   local escaped_versionname_pattern
   local escaped_versionname_value
   local escaped_value

   r_escaped_sed_pattern "${versionname}"
   escaped_versionname_pattern="${RVAL}"

   r_escaped_sed_replacement "${versionname}"
   escaped_versionname_value="${RVAL}"

   local sed_script

   log_debug "Using ${scheme} scheme"

   case "${scheme}" in
      "<<")
         value="(($major << 20) | ($minor << 8) | $patch)"

         r_escaped_sed_replacement "${value}"
         escaped_value="${RVAL}"

         RVAL='s/^\(.*\)'
         r_append "${RVAL}" "${escaped_versionname_pattern}"
         r_append "${RVAL}" '\([^0-9()]*\)( *( *[0-9][0-9]* *<< *20 *) *| *( *[0-9][0-9]* *<< *8 *) *| *[0-9][0-9]* *)\(.*\)$/'
         r_append "${RVAL}" '\1'
         r_append "${RVAL}" "${escaped_versionname_value}"
         r_append "${RVAL}" '\2'
         r_append "${RVAL}" "${escaped_value}"
         r_append "${RVAL}" '\3/'
         sed_script="${RVAL}"

         inplace_sed -e "${sed_script}" "${versionfile}" || fail "could not set version number"
      ;;

      "1.2.3"|"1.2.3.4")
         if [ "${scheme}" = "1.2.3.4" ]
         then
            value="$major.$minor.$patch.$custom"
         else
            value="$major.$minor.$patch"
         fi

         r_escaped_sed_replacement "${value}"
         escaped_value="${RVAL}"

         if [ ! -z "${versionname}" ]
         then
            RVAL='s/^\(.*\)'
            r_append "${RVAL}" "${escaped_versionname_pattern}"
            if [ "${scheme}" = "1.2.3.4" ]
            then
               r_append "${RVAL}" '\([^0-9]*\)[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\(.*\)$/'
            else
               r_append "${RVAL}" '\([^0-9]*\)[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\(.*\)$/'
            fi
            r_append "${RVAL}" '\1'
            r_append "${RVAL}" "${escaped_versionname_value}"
            r_append "${RVAL}" '\2'
            r_append "${RVAL}" "${escaped_value}"
            r_append "${RVAL}" '\3/'
         else
            RVAL='s/^\([^0-9]*\)[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/'
            r_append "${RVAL}" "${escaped_value}"
            r_append "${RVAL}" '/'
         fi
         sed_script="${RVAL}"
      ;;

      *)
         fail "Incompatible versioning scheme in \"${versionfile}\".
${C_INFO}Use either 1.2.3[.4] or ((1 << 20) | (2 << 8) | 3)"
      ;;
   esac

   inplace_sed -e "${sed_script}" "${versionfile}"
}

