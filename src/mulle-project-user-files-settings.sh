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

#######
# Load in some user file, that define permanent info
#######

INFO_DIR="${INFO_DIR:-.mulle/etc/project}"

project::user-files-settings::source_file()
{
   if [ "${VERBOSE}" = 'YES' ]
   then
      echo "Read \"$1\"" >&2
   fi
   . "$1"
}


# if there is a version-info.sh file read it
if [ -f "${INFO_DIR}/version-info.sh" ]
then
   DO_GIT_RELEASE='YES'
   project::user-files-settings::source_file "${INFO_DIR}/version-info.sh"
fi

# if there is a formula-info.sh file read it
if [ -f "${INFO_DIR}/formula-info.sh" ]
then
   DO_GENERATE_FORMULA='YES'
   DO_PUSH_FORMULA='YES'
   project::user-files-settings::source_file "${INFO_DIR}/formula-info.sh"
fi

# if there is a formula-info.sh file read it
if [ -f "${INFO_DIR}/publisher-info.sh" ]
then
   project::user-files-settings::source_file "${INFO_DIR}/publisher-info.sh"
fi

