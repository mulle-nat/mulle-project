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



get_header_from_name()
{
   echo "src/$1.h" | make_file_string
}


get_versionname_from_project()
{
   echo "$1_VERSION" | split_camelcase_string | make_cpp_string
}


get_project_version()
{
   local filename
   local versionname

   filename="$1"
   versionname="$2"

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
         sed -n 's/^[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/p' <<< "${match}"
      ;;
   esac
}


# legacy name
get_header_version()
{
   get_project_version "$@"
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


_git_check_remote()
{
   local name="$1"

   log_info "Check if remote \"${name}\" is present"
   exekutor git ls-remote -q --exit-code "${name}" > /dev/null
}


# Parameters!
#
# BRANCH
# ORIGIN
# TAG
#
_git_main()
{
   local branch
   local dstbranch
   local origin
   local tag
   local github

   branch="${1:-master}"
   [ $# -ne 0 ] && shift

   dstbranch="${1:-release}"
   [ $# -ne 0 ] && shift

   origin="${1:-origin}"
   [ $# -ne 0 ] && shift

   tag="$1"
   [ $# -ne 0 ] && shift

   github="$1"
   [ $# -ne 0 ] && shift

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

   case "${github}" in
      -*|"")
         fail "Invalid github \"${github}\""
      ;;
   esac

   log_verbose "Check clean state of project"
   exekutor git_must_be_clean               || return 1

   log_verbose "Check that the tag \"${tag}\" does not exist yet"
   exekutor git_tag_must_not_exist "${tag}" || return 1

   if ! _git_check_remote "${origin}"
   then
      log_error "\"${origin}\" not accessible"
      return 1
   fi

   #
   # make it a release
   #
   log_info "Push clean state of \"${branch}\" to \"${origin}\""
   exekutor git push "${origin}" "${branch}"  || return 1

   log_info "Make \"${dstbranch}\" a release, by rebasing on \"${branch}\""
   exekutor git checkout -B "${dstbranch}"    || return 1
   exekutor git rebase "${branch}"            || return 1

   # if rebase fails, we shouldn't be hitting tag now

   log_info "Tag \"${dstbranch}\" with \"${tag}\""
   exekutor git tag "${tag}"                    || return 1

   log_info "Push \"${dstbranch}\" with tags to \"${origin}\""
   exekutor git push "${origin}" "${dstbranch}" --tags || return 1

   if _git_check_remote "${github}"
   then
      log_info "Push \"${dstbranch}\" with tags to \"${github}\""
      exekutor git push "${github}" "${dstbranch}" --tags || return 1
   else
      log_info "There is no remote named \"${github}\""
   fi
}


git_main()
{
   local branch
   local rval

   log_verbose "Verify repository \"`pwd -P`\""

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-master}" # for dry run
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi

   _git_main "${branch}" "$@"
   rval=$?

   log_verbose "Checkout \"${branch}\" again"
   exekutor git checkout "${branch}" || return 1
   return $rval
}

:
