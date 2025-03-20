# shellcheck shell=bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
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


project::settings::_get_description_4()
{
   rexekutor head -4 "$1" \
   | grep -E '^####' \
   | sed -e 's/^####//' -e 's/^ //g' \
   | tr -d -c '[[:print:]]'
}


project::settings::_get_description_2()
{
   rexekutor sed -e '/^[[:space:]]*$/d' "$1" \
   | head -2 \
   | tail -1 \
   | tr -d -c '[[:print:]]'
}


project::settings::get_description()
{
   log_entry "project::settings::get_description" "$@"

   if [ ! -z "${DESC:-"${PROJECT_DESCRIPTION}"}" ]
   then
      log_fluff "Got description from environment"
      printf "%s\n" "${DESC:-"${PROJECT_DESCRIPTION}"}"
   else
      if [ -f "cola/properties.plist" ]
      then
         if MULLE_PQ="`command -v 'mulle-pq'`"
         then
            log_fluff "Got description from cola/properties.plist via pq"
            rexekutor "${MULLE_PQ}" --in cola/properties.plist \
                                    '.project.description' \
            | sed -e 's/^"\(.*\)".*$/\1/'
         else
            log_fluff "Got description from cola/properties.plist"
            rexekutor grep -E '^[[:space:]]*description=' cola/properties.plist \
            | sed -n -e 's/^.*description="\(.*\)";/\1/p;q'
         fi
      else
         if [ -f "README.md" ]
         then
            log_fluff "Got description from README.md"
            if ! project::settings::_get_description_4 "README.md"
            then
               project::settings::_get_description_2 "README.md"
            fi
         fi
      fi
   fi
}
