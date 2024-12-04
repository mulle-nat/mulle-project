#! /usr/bin/env mulle-bash
#! MULLE_BASHFUNCTIONS_VERSION=<|MULLE_BASHFUNCTIONS_VERSION|>
# shellcheck shell=bash
#
#
#  mulle-project-git-edit-comment.sh
#  mulle-project
#
#  Copyright (c) 2024 Nat! - Mulle kybernetiK.
#  All rights reserved.
#
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
#  Neither the name of Mulle kybernetiK nor the names of its contributors
#  may be used to endorse or promote products derived from this software
#  without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#


[ "${TRACE}" = 'YES' -o "${MULLE_PROJECT_GIT_EDIT_COMMENT_TRACE}" = 'YES' ] \
&& set -x  \
&& : "$0" "$@"

### Inject code for standalone script with \`mulle-bashfunctions embed\`
### >> START OF mulle-boot.sh >>
### << END OF mulle-boot.sh <<

#
# Versioning of this script
#
MULLE_EXECUTABLE_VERSION="0.0.0"


### Inject code for standalone script with \`mulle-bashfunctions embed\`
### >> START OF mulle-bashfunctions-embed.sh >>
### << END OF mulle-bashfunctions-embed.sh <<

project_git_edit_comment::print_flags()
{
   echo "   -f        : force operation"
   echo "   -i        : interactive commit"
   echo "   -m <text> : new message text"
   echo "   -o <text> : old message text"

   options_technical_flags_usage \
                "     : "
}


project_git_edit_comment::usage()
{
   [ $# -ne 0 ] && log_error "$*"


   cat <<EOF >&2
Usage:
   mulle-project-git-edit-comment [flags]

   Change a comment text in git.

Flags:
EOF
   project_git_edit_comment::print_flags | LC_ALL=C sort >&2

   exit 1
}


project_git_edit_comment::main()
{
   #
   # simple option/flag handling
   #
   local OPTION_OLD_MESSAGE
   local OPTION_NEW_MESSAGE
   local OPTION_INTERACTIVE='NO'

   while [ $# -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -f|--force)
            MULLE_FLAG_MAGNUM_FORCE='YES'
         ;;

         -h*|--help|help)
            project_git_edit_comment::usage
         ;;

         -i)
            OPTION_INTERACTIVE='YES'
         ;;

         -o|--old|--old-message)
            [ $# -eq 1 ] && project_git_edit_comment::usage "missing argument to $1"
            shift

            OPTION_OLD_MESSAGE="$1"
         ;;

         -m|--new|--new-message)
            [ $# -eq 1 ] && project_git_edit_comment::usage "missing argument to $1"
            shift

            OPTION_NEW_MESSAGE="$1"
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         -*)
            project_git_edit_comment::usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   [ -z "${OPTION_OLD_MESSAGE}" ] && fail "old can't be empty"
   [ -z "${OPTION_NEW_MESSAGE}" -a "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ] && fail "new can't be empty, or use -f"

   [ ! -d .git ] && fail "No .git repository found"
   # Find the commit with the old message
   r_escaped_grep_pattern "${OPTION_OLD_MESSAGE}"
   COMMIT_HASH=$(rexekutor git log --grep="${RVAL}" --format="%H" -n 1)

   if [ -z "$COMMIT_HASH" ]
   then
      log_verbose "Commit message not found"
      return 0
   fi

   if [ "${OPTION_INTERACTIVE}" = 'YES' ]
   then
      local escaped_old
      # Rebase to the commit before the one we want to change
      r_escaped_doublequotes "${OPTION_OLD_MESSAGE}"
      r_escaped_doublequotes "${RVAL}"
      escaped_old="${RVAL}"

      local escaped_new

      r_escaped_doublequotes "${OPTION_NEW_MESSAGE}"
      r_escaped_doublequotes "${RVAL}"
      escaped_new="${RVAL}"


      exekutor git rebase -i "$COMMIT_HASH~1" \
                          -x "if [ \"\$(git log -1 --format='%s')\" = \"$escaped_old\" ]; then git commit --amend -m \"$escaped_new\" --allow-empty; fi"
   else
      local escaped_old

      r_escaped_sed_pattern "${OPTION_OLD_MESSAGE}"
      escaped_old="${RVAL}"

      local escaped_new

      r_escaped_sed_pattern "${OPTION_NEW_MESSAGE}"
      escaped_new="${RVAL}"

      exekutor git filter-branch --msg-filter '
            sed "s/^'"$escaped_old"'$/'"$escaped_new"'/"
        ' -- --all
      log_info "Commit message updated"
   fi
}

#
# You can also use the function `call_with_flags`, which has been defined
# during mulle-boot. It lets you call 'project_git_edit_comment::main'
# with MULLE_PROJECT_GIT_EDIT_COMMENT_FLAGS interposed.
#
# call_with_flags "project_git_edit_comment::main" "${MULLE_PROJECT_GIT_EDIT_COMMENT_FLAGS}" "$@"

project_git_edit_comment::main "$@"
