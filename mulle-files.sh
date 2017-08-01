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

EXE_DIR="`dirname -- $0`"

# if there is a version-info.sh file read it
if [ -f "${EXE_DIR}/version-info.sh" ]
then
   DO_GIT_RELEASE="YES"
   . "${EXE_DIR}/version-info.sh"
fi

#
# if there is a release-info.sh file read it
# this an old fashioned name for version-info.sh
#
if [ -f "${EXE_DIR}/release-info.sh" ]
then
   DO_GIT_RELEASE="YES"
   . "${EXE_DIR}/release-info.sh"
fi

# if there is a formula-info.sh file read it
if [ -f "${EXE_DIR}/formula-info.sh" ]
then
   DO_GENERATE_FORMULA="YES"
   . "${EXE_DIR}/formula-info.sh"
fi

#
# If there is a - possibly .gitignored - tap-info.sh file read it.
# It could store PUBLISHER and PUBLISHER_TAP
#
if [ -f "${EXE_DIR}/tap-info.sh" ]
then
   . "${EXE_DIR}/tap-info.sh"
fi


# if there is a post-release.sh file read it
if [ -f "${EXE_DIR}/post-release.sh" ]
then
   . "${EXE_DIR}/post-release.sh"
fi
