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
MULLE_PROJECT_GIT_SH="included"


project::git::tag_exists()
{
   log_entry "project::git::tag_exists" "$@"

   local tag="$1"

   rexekutor git rev-parse --quiet --verify "${tag}" > /dev/null 2>&1
}


project::git::branch_exists()
{
   log_entry "project::git::branch_exists" "$@"

   local branch="$1"

   rexekutor git rev-parse --quiet --verify "${branch}" > /dev/null 2>&1
}


project::git::ref_for_tag()
{
   log_entry "project::git::ref_for_tag" "$@"

   rexekutor git show-ref --tags $1 | awk '{ print$1 }'
}


project::git::any_first_commit()
{
   log_entry "project::git::any_first_commit" "$@"

   rexekutor git rev-list HEAD | tail -n 1
}


project::git::last_tag()
{
   log_entry "project::git::last_tag" "$@"

   rexekutor git tag --sort=-v:committerdate | head -1
}


project::git::commits_from_start()
{
   log_entry "project::git::commits_from_start" "$@"

   rexekutor git log --format=%B
}


project::git::commits_from_ref()
{
   log_entry "project::git::commits_from_ref" "$@"

   rexekutor git log --format=%B "$1..HEAD"
}


project::git::commits_from_tag()
{
   log_entry "project::git::commits_from_tag" "$@"

   local ref

   ref="`project::git::ref_for_tag "$1"`"
   project::git::commits_from_ref "$ref"
}


project::git::is_clean()
{
   log_entry "project::git::is_clean" "$@"

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


#
# branch can be empty, and usually is by default
#
project::git::can_amend()
{
   log_entry "project::git::can_amend" "$@"

   local branch="$1"

   # if 0 then egrep matched and this means that HEAD has no tags or
   # has been pushed to any remotes

   # branch can be empty!!
   git log -1 --decorate -q ${branch} | egrep '\(HEAD -> [^,)]*\)' > /dev/null
   if [ $? -ne 0 ]
   then
      log_debug "Last commit has been pushed already or is tagged already"
      return 1
   fi

   #
   # check that last commit wasn't a merge, don't want to amend those
   #
   git log -1 --pretty="%B" | head -1 | egrep '^Merge branch' > /dev/null
   if [ $? -eq 0 ]
   then
      log_debug "Last commit is a merge from another branch"
      return 1
   fi

   return 0
}

# more convenient if not exekutored!
project::git::can_push()
{
   log_entry "project::git::can_push" "$@"

   local remote="${1:-origin}"
   local branch="${2:-release}"

   local result

   if ! exekutor git fetch -q "${remote}" "${branch}"
   then
      return 1
   fi

   result="`rexekutor git rev-list --left-right "HEAD...${remote}/${branch}" --ignore-submodules --count 2> /dev/null`"
   if [ $? -ne 0 ]
   then
      log_verbose "Remote \"${remote}\" does not have branch \"${branch}\" yet"
      return 0
   fi
   result="`awk '{ print $2 }' <<< "${result}" `"
   [ -z "${result}" ] || [ "${result}" -eq 0 ]  # -z test for exekutor
}


project::git::remote_branch_is_synced()
{
   log_entry "project::git::remote_branch_is_synced" "$@"

   local remote="${1:-origin}"
   local branch="${2:-release}"

   local no_change

   # get 0 0, don't know if spacing is always same
   no_change="`rexekutor git rev-list --left-right "HEAD...HEAD" --ignore-submodules --count 2> /dev/null`"

   if ! exekutor git fetch -q "${remote}" "${branch}"
   then
      return 2
   fi

   local result

   result="`rexekutor git rev-list --left-right "HEAD...${remote}/${branch}" --ignore-submodules --count 2> /dev/null`"
   if [ $? -ne 0 ]
   then
      log_verbose "Remote \"${remote}\" does not have branch \"${branch}\" yet"
      return 0
   fi

   [ "${no_change}" = "${result}" ]
}


#
# 1 no-remote
# 2 remote there but no ref like name
#
# TODO: same code as in mulle-fetch fetch::git::is_valid_remote_url
#       consolidate into mulle-git or so
#
project::git::_check_remote()
{
   log_entry "project::git::_check_remote" "$@"

   local name="$1"

   [ -z "${name}" ] && _internal_fail "empty parameter"

   log_info "Check if remote \"${name}\" is present"

   #
   # memo -q --exit-code are basically useless, stuff still gets printed
   # e.g. GIT_ASKPASS=true git ls-remote -q --exit-code 'https://github.com/craftinfo/zlib-crafthelp.git'
   #
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      GIT_ASKPASS=true rexekutor git ls-remote -q --exit-code "$1" > /dev/null
      return $?
   fi

   GIT_ASKPASS=true rexekutor git ls-remote -q --exit-code "$1" > /dev/null 2>&1
}


project::git::untag_all()
{
   log_entry "project::git::untag_all" "$@"

   local tag="$1"

   local i
   local remote

   log_info "Trying to remove local tag \"${tag}\""
   exekutor git tag -d "$tag"

   # remotes are only present after a fetch, otherwise just in config
   (
      shell_enable_nullglob

      for i in ".git/refs/remotes"/*
      do
         r_basename "${i}"
         remote="${RVAL}"
         log_info "Trying to remove tag \"${tag}\" on remote \"${remote}\""
         exekutor git push "${remote}" ":${tag}" # failure is OK
      done
   )
}


project::git::_parse_params()
{
   branch="${1:-${GIT_DEFAULT_BRANCH:-master}}"
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

   forcepush="$1"
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


project::git::_verify_main()
{
   log_entry "project::git::_verify_main" "$@"

   local branch
   local dstbranch
   local origin
   local tag
   local github
   local latesttag
   local forcepush

   project::git::_parse_params "$@"

   local have_github
   local return_or_continue_if_dry_run

   return_or_continue_if_dry_run="return"
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      return_or_continue_if_dry_run=':'
   fi

   log_verbose "Verify repository \"`pwd -P`\""

   if project::git::_check_remote "${github}"
   then
      have_github='YES'
   else
      log_info "There is no remote named \"${github}\""
   fi

   log_verbose "Check clean state of project"
   if ! rexekutor project::git::is_clean
   then
      log_error "repository is tainted"
      ${return_or_continue_if_dry_run} 1
   fi

   if [ ! -z "${tag}" ]
   then
      if project::git::tag_exists "${tag}"
      then
         log_warning "Tag \"${tag}\" already exists"
      fi
   fi

   if ! project::git::_check_remote "${origin}"
   then
      log_error "\"${origin}\" not accessible (If present, maybe needs an initial push ?)"
      ${return_or_continue_if_dry_run} 1
   fi

   if [ "${forcepush}" != 'YES' ]
   then
      #
      # check that we can push
      #
      log_verbose "Check if remotes need merge"
      if ! project::git::can_push "${origin}" "${branch}"
      then
         log_error "You need to merge \"${origin}/${branch}\" first"
         ${return_or_continue_if_dry_run} 1
      fi

      if ! project::git::can_push "${origin}" "${dstbranch}"
      then
         log_error "You need to merge \"${origin}/${dstbranch}\" first"
         ${return_or_continue_if_dry_run} 1
      fi

      if [ "${have_github}" = 'YES' ]
      then
         if ! project::git::can_push "${github}" "${dstbranch}"
         then
            log_error "You need to merge \"${github}/${dstbranch}\" first"
            ${return_or_continue_if_dry_run} 1
         fi
      fi
   fi
}


# Parameters!
#
# BRANCH
# ORIGIN
# TAG
#
project::git::_commit_main()
{
   log_entry "project::git::_commit_main" "$@"

   local branch
   local dstbranch
   local origin
   local tag
   local github
   local latesttag
   local forcepush

   project::git::_parse_params "$@"

   local have_github

   if project::git::_check_remote "${github}"
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
      if rexekutor project::git::tag_exists "${tag}"
      then
         log_error "Tag \"${tag}\" already exists"
         ${return_or_continue_if_dry_run} 4
      fi
   fi

   local gitpushflags

   if [ "${forcepush}" = 'YES' ]
   then
      gitpushflags="-f"
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
      project::git::untag_all "${latesttag}"

      log_info "Tag \"${dstbranch}\" with \"${latesttag}\""
      exekutor git tag "${latesttag}"         || ${return_or_continue_if_dry_run} 1
   fi

   log_info "Push \"${dstbranch}\" with tags to \"${origin}\""
   exekutor git push ${gitpushflags} "${origin}" "${dstbranch}" || ${return_or_continue_if_dry_run} 1
   if [ ! -z "${tag}" ]
   then
      exekutor git push ${gitpushflags} "${origin}" "${tag}" || ${return_or_continue_if_dry_run} 1
   fi
   if [ ! -z "${latesttag}" ]
   then
      exekutor git push ${gitpushflags}  "${origin}" "${latesttag}" || ${return_or_continue_if_dry_run} 1
   fi

   if [ "${have_github}" = 'YES' ]
   then
      log_info "Push \"${dstbranch}\" with tags to \"${github}\""
      exekutor git push ${gitpushflags} "${github}" "${dstbranch}" || ${return_or_continue_if_dry_run} 1

      if [ ! -z "${tag}" ]
      then
         exekutor git push ${gitpushflags} "${github}" "${tag}" || ${return_or_continue_if_dry_run} 1
      fi
      if [ ! -z "${latesttag}" ]
      then
         exekutor git push ${gitpushflags} "${github}" "${latesttag}" || ${return_or_continue_if_dry_run} 1
      fi
   fi
}


project::git::verify_main()
{
   log_entry "project::git::verify_main" "$@"

   local branch

   branch="`rexekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-${GIT_DEFAULT_BRANCH:-master}}" # for dry run

   project::git::_verify_main "${branch}" "$@"

   return $?
}


project::git::assert_not_on_release_branch()
{
   local branch

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-${GIT_DEFAULT_BRANCH:-master}}" # for dry run
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi
}


project::git::r_commit_options()
{
   log_entry project::git::r_commit_options "$@"

   local amend="$1"
   local message="$2"

   case "${amend}" in
      'YES')
         if project::git::can_amend
         then
            _log_warning "Last commit was tagged or merged or pushed. You may \
need to force push to remotes now."
         fi
         RVAL="--amend --no-edit"
      ;;

      'NO')
         r_escaped_singlequotes "${message}"
         RVAL="-m '${RVAL}'"
      ;;

      'DEFAULT'|'SAFE')
         if ! project::git::can_amend
         then
            _log_verbose "Will create a new commit as the last commit has been \
tagged or merged or pushed"

            r_escaped_singlequotes "${message}"
            RVAL="-m '${RVAL}'"
         else
            RVAL="--amend --no-edit"
         fi
      ;;

      'ONLY')
         if ! project::git::can_amend
         then
            fail "Can not amend last commit as its been tagged or merged or pushed"
         fi
         RVAL="--amend --no-edit"
      ;;

      *)
         _internal_fail "must specify an amend option"
      ;;
   esac
}


project::git::append_to_gitignore_if_needed()
{
   local file="$1"

   r_trim_whitespace "${file}"
   file="${RVAL}"

   case "${file}" in
      ""|\#*)
         # log_warning 'Fool! Don''t add comments this way!'
         return
      ;;
   esac

   local line

   if [ -f ".gitignore" ]
   then
      case "${file}" in
         */*)
            local directory

            directory="${file##/}"
            directory="${directory%%/}"

            local pattern0
            local pattern1
            local pattern2
            local pattern3

            # variations with leading and trailing slashes
            pattern0="${directory}"
            pattern1="${directory}/"
            pattern2="/${directory}"
            pattern3="/${directory}/"

            if rexekutor fgrep -q -s -x -e "${pattern0}" .gitignore
            then
               log_verbose "Duplicate ${C_RESET_BOLD}${pattern0}${C_VERBOSE} found"
               return
            fi
            if rexekutor fgrep -q -s -x -e "${pattern1}" .gitignore
            then
               log_verbose "Duplicate ${C_RESET_BOLD}${pattern1}${C_VERBOSE} found"
               return
            fi
            if rexekutor fgrep -q -s -x -e "${pattern2}" .gitignore
            then
               log_verbose "Duplicate ${C_RESET_BOLD}${pattern2}${C_VERBOSE} found"
               return
            fi
            if rexekutor fgrep -q -s -x -e "${pattern3}" .gitignore
            then
               log_verbose "Duplicate ${C_RESET_BOLD}${pattern3}${C_VERBOSE} found"
               return
            fi
         ;;

         *)
            if rexekutor fgrep -q -s -x -e "${file}" .gitignore
            then
               log_verbose "Duplicate ${C_RESET_BOLD}${file}${C_VERBOSE} found"
               return
            fi
         ;;
      esac
   fi

   #
   # prepend \n because it is safer, in case .gitignore has no trailing
   # LF which it often seems to not have
   # fgrep is bugged on at least OS X 10.x, so can't use -e chaining

   local terminator
   local line

   line="${file}"
   terminator="`rexekutor tail -c 1 ".gitignore" 2> /dev/null | tr '\012' '|'`"

   if [ ! -z "${terminator}" -a "${terminator}" != "|" ]
   then
      line=$'\n'"${line}"
   fi

   log_info "Adding \"${file}\" to \".gitignore\""
   redirect_append_exekutor .gitignore printf "%s\n" "${line}" || fail "Couldn't append to .gitignore"
}


project::git::main()
{
   log_entry "project::git::main" "$@"

   local branch
   local rval

   branch="`exekutor git rev-parse --abbrev-ref HEAD`"
   branch="${branch:-${GIT_DEFAULT_BRANCH:-master}}" # for dry run
   if [ "${branch}" = "release" ]
   then
      fail "Don't call it from release branch"
   fi

   project::git::_commit_main "${branch}" "$@"
   rval=$?

   # not sure why I didn't do this always before
   log_verbose "Checkout \"${branch}\" again"
   exekutor git checkout "${branch}"

   return $rval
}

:
