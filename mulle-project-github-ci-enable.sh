#! /usr/bin/env mulle-bash
#! MULLE_BASHFUNCTIONS_VERSION=<|MULLE_BASHFUNCTIONS_VERSION|>
# shellcheck shell=bash
#
#
#  mulle-project-github-ci-status.sh
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


[ "${TRACE}" = 'YES' -o "${MULLE_PROJECT_GITHUB_CI_STATUS_TRACE}" = 'YES' ] \
&& set -x  \
&& : "$0" "$@"

### Inject code for standalone script with \`mulle-bashfunctions embed\`
### >> START OF mulle-boot.sh >>
### << END OF mulle-boot.sh <<

#
# Versioning of this script
#
MULLE_EXECUTABLE_VERSION="0.0.0"


r_dirname "${MULLE_USER_PWD}"
r_basename "${RVAL}"
OWNER="${RVAL}"

r_basename "${MULLE_USER_PWD}"
REPO="${RVAL}"

#!/bin/bash
TOKEN="${GITHUB_TOKEN}"
OWNER="${GITHUB_NAME:-${OWNER:-${USER:-${LOGNAME:-unknown}}}}"
REPO="${REPO}"


### Inject code for standalone script with \`mulle-bashfunctions embed\`
### >> START OF mulle-bashfunctions-embed.sh >>
### << END OF mulle-bashfunctions-embed.sh <<

project_github_ci_enable::print_flags()
{
   echo "   -f                  : force operation"
   echo "   --token <n>         : github token (${TOKEN:0:8}...)"
   echo "   --owner <name>      : github owner (${OWNER})"
   echo "   --repo <name>       : name of the repository (${REPO})"

   ##
   ## ADD YOUR FLAGS DESCRIPTIONS HERE
   ##

   options_technical_flags_usage \
                "               : "
}


project_github_ci_enable::usage()
{
   [ $# -ne 0 ] && log_error "$*"


   cat <<EOF >&2
Usage:
   mulle-project-github-ci-enable [flags] <cmd>

   Enable or disable ALL github workflows.

Commands:
   list    : list workflow names
   enable  : enable all
   disable : enable all

Flags:
EOF
   project_github_ci_enable::print_flags | LC_ALL=C sort >&2

   exit 1
}


project_github_ci_enable::enable()
{
   log_entry "project_github_ci_enable::enable" "$@"

   local enable="$1"
   local workflows="$2"

   local verb

   verb="${enable%e}ing"
   verb="${verb^}"

# Disable each workflow
   while read -r workflow_id
   do
      printf "%s workflow ID: %s\n" "${verb}"" ${workflow_id}"
      exekutor curl -X PUT \
                    -H "Authorization: token $TOKEN" \
                    "https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$workflow_id/${enable}"

   done < <( jq -r '.workflows[] | .id' <<< "$workflows" )
}


project_github_ci_enable::main()
{
   #
   # simple option/flag handling
   #
   local OPTION_WORKFLOW_NAME="CI"
   local OPTION_COUNT="1"
   local OPTION_STALE_DIFF="7 days"

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
            project_github_ci_enable::usage
         ;;

         --name|--owner|--github-name)
            [ $# -eq 1 ] && project_github_ci_enable::usage "missing argument to $1"
            shift

            OWNER="$1"
         ;;

         --repo|--repository|--repo-name)
            [ $# -eq 1 ] && project_github_ci_enable::usage "missing argument to $1"
            shift

            REPO="$1"
         ;;

         --token|--github-token)
            [ $# -eq 1 ] && project_github_ci_enable::usage "missing argument to $1"
            shift

            TOKEN="$1"
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         -*)
            project_github_ci_enable::usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   local workflows
   local url

   url="https://api.github.com/repos/$OWNER/$REPO/actions/workflows"
   # Get all workflow files

   if [ -z "${TOKEN}" ]
   then
      fail "Need a valid GITHUB_TOKEN in the environment or as option"
   fi

   workflows=$(rexekutor curl -s -H "Authorization: token $TOKEN" "${url}")
   if [ -z "${workflows}" ]
   then
      log_warning "https://github.com/$OWNER/$REPO has no workflows"
      return 0
   fi

   if [[ $(jq 'has("status") and .status != "200"' <<< "${workflows}") == "true" ]]
   then
      fail "github API request failed: ${workflows}"
   fi

   log_debug "workflows: ${workflows}"

   case "${1:-list}" in
      list)
         jq -r '.workflows[] | .name' <<< "${workflows}"
      ;;

      enable|disable)
         project_github_ci_enable::enable "$1" "${workflows}"
      ;;

      *)
         project_github_ci_enable::usage "unknown command \"$1\""
      ;;
   esac
}

#
# You can also use the function `call_with_flags`, which has been defined
# during mulle-boot. It lets you call 'project_github_ci_enable::main'
# with MULLE_PROJECT_GITHUB_CI_STATUS_FLAGS interposed.
#
# call_with_flags "project_github_ci_enable::main" "${MULLE_PROJECT_GITHUB_CI_STATUS_FLAGS}" "$@"

project_github_ci_enable::main "$@"
