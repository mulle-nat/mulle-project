#! /usr/bin/env mulle-bash
#! MULLE_BASHFUNCTIONS_VERSION=<|MULLE_BASHFUNCTIONS_VERSION|>
# shellcheck shell=bash
#
#
#  mulle-project-github-rename-default-branch.sh
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


[ "${TRACE}" = 'YES' -o "${MULLE_PROJECT_GITHUB_RENAME_DEFAULT_BRANCH_TRACE}" = 'YES' ] \
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

project_github_rename_default_branch::print_flags()
{
   echo "   -f    : force operation"

   options_technical_flags_usage \
                "         : "
}


project_github_rename_default_branch::usage()
{
   [ $# -ne 0 ] && log_error "$*"


   cat <<EOF >&2
Usage:
   mulle-project-github-rename-default-branch [flags] [old] [new]

   Rename the default branch <old> on github to <new>. It's assumed that
   <new> does not exist. 

   Default values: 
   
      old : "release"
      new : "master"

Flags:
EOF
   project_github_rename_default_branch::print_flags | LC_ALL=C sort >&2

   exit 1
}


project_github_rename_default_branch::main()
{
   #
   # simple option/flag handling
   #
   local OPTION_VALUE

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
            project_github_rename_default_branch::usage
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;


         -*)
            project_github_rename_default_branch::usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   local old="${1:-release}" 
   local new="${2:-master}"

   [ $# -gt 2 ] && shift 2 &&  project_github_rename_default_branch::usage "Superflous arguments: $*"
         
   # Create a new "new" branch from "release"
   gh api --method POST /repos/:owner/:repo/git/refs \
          -f ref="refs/heads/${new}" \
          -f sha="$(gh api "repos/:owner/:repo/git/refs/heads/${old}" --jq .object.sha)"

   # Set "new" as the default branch
   gh repo edit --default-branch "${new}"

   # Delete the "old" branch
   gh api --method DELETE "/repos/:owner/:repo/git/refs/heads/${old}"
}

#
# You can also use the function `call_with_flags`, which has been defined
# during mulle-boot. It lets you call 'project_github_rename_default_branch::main'
# with MULLE_PROJECT_GITHUB_RENAME_DEFAULT_BRANCH_FLAGS interposed.
#
# call_with_flags "project_github_rename_default_branch::main" "${MULLE_PROJECT_GITHUB_RENAME_DEFAULT_BRANCH_FLAGS}" "$@"

project_github_rename_default_branch::main "$@"
