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

git_tag_exists()
{
   log_entry "git_tag_exists" "$@"

   local tag="$1"

   rexekutor git rev-parse "${tag}" > /dev/null 2>&1
}


git_ref_for_tag()
{
   log_entry "git_ref_for_tag" "$@"

   rexekutor git show-ref --tags $1 | awk '{ print$1 }'
}


git_any_first_commit()
{
   log_entry "git_any_first_commit" "$@"

   rexekutor git rev-list HEAD | tail -n 1
}


git_last_tag()
{
   log_entry "git_last_tag" "$@"

   rexekutor git describe --tags --abbrev=0 2> /dev/null
}


git_commits_from_start()
{
   log_entry "git_commits_from_start" "$@"

   rexekutor git log --format=%B
}


git_commits_from_ref()
{
   log_entry "git_commits_from_ref" "$@"

   rexekutor git log --format=%B "$1..HEAD"
}


git_commits_from_tag()
{
   log_entry "git_commits_from_tag" "$@"

   local ref

   ref="`git_ref_for_tag "$1"`"
   git_commits_from_ref "$ref"
}


git_is_clean()
{
   log_entry "git_is_clean" "$@"

   local name

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      log_error "\"${name}\" is not a git repository"
      return 1
   fi

   local clean

   clean=`rexekutor git status -s --untracked-files=no`
   [ "${clean}" = "" ]
}


# more convenient if not exekutored!
git_repo_can_push()
{
   log_entry "git_repo_can_push" "$@"

   local remote="${1:-origin}"
   local branch="${2:-release}"

   local result

   exekutor git fetch -q "${remote}" "${branch}"
   result="`rexekutor git rev-list --left-right "HEAD...${remote}/${branch}" --ignore-submodules --count 2> /dev/null`"
   if [ $? -ne 0 ]
   then
      log_verbose "Remote \"${remote}\" does not have branch \"${branch}\" yet"
      return 0
   fi
   result="`printf "%s\n" "${result}" | awk '{ print $2 }'`"
   [ -z "${result}" ] || [ "${result}" -eq 0 ]  # -z test for exekutor
}


_git_check_remote()
{
   log_entry "_git_check_remote" "$@"

   local name="$1"

   log_info "Check if remote \"${name}\" is present"
   rexekutor git ls-remote -q --exit-code "${name}" > /dev/null 2> /dev/null
}


git_untag_all()
{
   log_entry "git_untag_all" "$@"

   local tag="$1"

   local i
   local remote

   log_info "Trying to remove local tag \"${tag}\""
   exekutor git tag -d "$tag"

   # remotes are only present after a fetch, otherwise just in config
   (
      shopt -s nullglob

      for i in ".git/refs/remotes"/*
      do
         r_basename "${i}"
         remote="${RVAL}"
         log_info "Trying to remove tag \"${tag}\" on remote \"${remote}\""
         exekutor git push "${remote}" ":${tag}" # failure is OK
      done
   )
}


_git_parse_params()
{
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

   latesttag="$1"
   [ $# -ne 0 ] && shift

   case "${tag}" in
      -*)
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
}


_git_verify_main()
{
   log_entry "_git_verify_main" "$@"

   local branch
   local dstbranch
   local origin
   local tag
   local github
   local latesttag

   _git_parse_params "$@"

   local have_github
   local return_or_continue_if_dry_run

   return_or_continue_if_dry_run="return"
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return_or_continue_if_dry_run=':'
   fi

   log_verbose "Verify repository \"`pwd -P`\""

   if _git_check_remote "${github}"
   then
      have_github='YES'
   else
      log_info "There is no remote named \"${github}\""
   fi

   log_verbose "Check clean state of project"
   if ! rexekutor git_is_clean
   then
      log_error "repository is tainted"
      ${return_or_continue_if_dry_run} 1
   fi

   if [ ! -z "${tag}" ]
   then
      if git_tag_exists "${tag}"
      then
         log_warning "Tag \"${tag}\" already exists"
      fi
   fi

   if ! _git_check_remote "${origin}"
   then
      log_error "\"${origin}\" not accessible (If present, maybe needs an initial push ?)"
      ${return_or_continue_if_dry_run} 1
   fi

   #
   # check that we can push
   #
   log_verbose "Check if remotes need merge"
   if ! git_repo_can_push "${origin}" "${branch}"
   then
      log_error "You need to merge \"${origin}/${branch}\" first"
      ${return_or_continue_if_dry_run} 1
   fi

   if ! git_repo_can_push "${origin}" "${dstbranch}"
   then
      log_error "You need to merge \"${origin}/${dstbranch}\" first"
      ${return_or_continue_if_dry_run} 1
   fi

   if [ "${have_github}" = 'YES' ]
   then
      if ! git_repo_can_push "${github}" "${dstbranch}"
      then
         log_error "You need to merge \"${github}/${dstbranch}\" first"
         ${return_or_continue_if_dry_run} 1
      fi
   fi
}


# Parameters!
#
# BRANCH
# ORIGIN
# TAG
#
_git_commit_main()
{
   log_entry "_git_commit_main" "$@"

   local branch
   local dstbranch
   local origin
   local tag
   local github
   local latesttag

   _git_parse_params "$@"

   local have_github

   if _git_check_remote "${github}"
   then
      have_github='YES'
   fi

   local return_or_continue_if_dry_run

   return_or_continue_if_dry_run="return"
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return_or_continue_if_dry_run=':'
   fi

   if [ ! -z "${tag}" ]
   then
      log_verbose "Check that the tag \"${tag}\" does not exist yet"
      if rexekutor git_tag_exists "${tag}"
      then
         log_error "Tag \"${tag}\" already exists"
         ${return_or_continue_if_dry_run} 4
      fi
   fi

   #
   # make it a release
   #
   log_info "Push clean state of \"${branch}\" to \"${origin}\""
   exekutor git push "${origin}" "${branch}"  || ${return_or_continue_if_dry_run} 1

   log_info "Make \"${dstbranch}\" a release, by rebasing on \"${branch}\""
   exekutor git checkout -B "${dstbranch}"    || ${return_or_continue_if_dry_run} 1
   exekutor git rebase "${branch}"            || ${return_or_continue_if_dry_run} 1

   # if rebase fails, we shouldn't be hitting tag now

   if [ ! -z "${tag}" ]
   then
      log_info "Tag \"${dstbranch}\" with \"${tag}\""
      exekutor git tag "${tag}"                  || ${return_or_continue_if_dry_run} 1
   fi

   if [ ! -z "${latesttag}" ]
   then
      log_info "Untag \"${dstbranch}\" with \"${latesttag}\""
      git_untag_all "${latesttag}"

      log_info "Tag \"${dstbranch}\" with \"${latesttag}\""
      exekutor git tag "${latesttag}"         || ${return_or_continue_if_dry_run} 1
   fi

   log_info "Push \"${dstbranch}\" with tags to \"${origin}\""
   exekutor git push "${origin}" "${dstbranch}" --tags || ${return_or_continue_if_dry_run} 1

   if [ "${have_github}" = 'YES' ]
   then
      log_info "Push \"${dstbranch}\" with tags to \"${github}\""
      exekutor git push "${github}" "${dstbranch}" --tags || ${return_or_continue_if_dry_run} 1
   fi
}


git_verify_main()
{
   log_entry "git_verify_main" "$@"

   local branch

   branch="`rexekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-master}" # for dry run

   _git_verify_main "${branch}" "$@"

   return $?
}


git_assert_not_on_release_branch()
{
   local branch

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-master}" # for dry run
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi
}

git_commit_main()
{
   log_entry "git_commit_main" "$@"

   local branch
   local rval

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-master}" # for dry run
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi

   _git_commit_main "${branch}" "$@"
   rval=$?

   # not sure why I didn't do this always before
   log_verbose "Checkout \"${branch}\" again"
   exekutor git checkout "${branch}"

   return $rval
}

:
