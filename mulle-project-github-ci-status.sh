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


### Inject code for standalone script with \`mulle-bashfunctions embed\`
### >> START OF mulle-bashfunctions-embed.sh >>
### << END OF mulle-bashfunctions-embed.sh <<

project_github_ci_status::print_flags()
{
   echo "   -f                  : force operation"
   echo "   --count <n>         : output state for last n runs (${OPTION_COUNT})"
   echo "   --stale-time <diff> : time after which a run is considered stale (${OPTION_STALE_DIFF})"
   echo "   --workflow <name>   : name of the CI workflow (${OPTION_WORKFLOW_NAME})"

   ##
   ## ADD YOUR FLAGS DESCRIPTIONS HERE
   ##

   options_technical_flags_usage \
                "               : "
}


project_github_ci_status::usage()
{
   [ $# -ne 0 ] && log_error "$*"


   cat <<EOF >&2
Usage:
   mulle-project-github-ci-status [flags]

   Show github status of latest CI run in a succinct way. If the CI hasn't
   run in a week, label it as outdated.

Flags:
EOF
   project_github_ci_status::print_flags | LC_ALL=C sort >&2

   exit 1
}


# Function to check if a date is older than a week
is_date_older_than_a_week()
{
  local date="$1"
  local diff="$2"

  local current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local one_week_ago=$(date -u -d "$current_date - ${diff}" +"%Y-%m-%dT%H:%M:%SZ")

  if [[ "$date" < "$one_week_ago" ]]; then
    return 0 # True: Date is older than a week
  else
    return 1 # False: Date is not older than a week
  fi
}


project_github_ci_status::verify()
{
   log_entry "project_github_ci_status::verify" "$@"

   local json_input="$1"
   local diff="$2"

   local conclusion
   local started_at

   # Parse JSON using jq
   conclusion=$(echo "$json_input" | jq -r '.[0].conclusion')
   started_at=$(echo "$json_input" | jq -r '.[0].startedAt')

   # Check conclusion
   if [[ "$conclusion" != "success" ]]
   then
      if [[ ! -z "$conclusion" ]]
      then
         log_info "${C_ERROR}${conclusion:-working}"
         return 1
      fi
      log_info "working"
      return 0
   fi

   # Check if date is older than a week
   if is_date_older_than_a_week "$started_at" "${diff}"
   then
      log_info "${C_WARNING}outdated"
      return 2
   fi

   log_info "${conclusion}"
}


project_github_ci_status::main()
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
            project_github_ci_status::usage
         ;;

         --count)
            [ $# -eq 1 ] && project_github_ci_status::usage "missing argument to $1"
            shift

            OPTION_COUNT="$1"
         ;;

         --stale-time)
            [ $# -eq 1 ] && project_github_ci_status::usage "missing argument to $1"
            shift

            OPTION_STALE_DIFF="$1"
         ;;

         --workflow)
            [ $# -eq 1 ] && project_github_ci_status::usage "missing argument to $1"
            shift

            OPTION_WORKFLOW_NAME="$1"
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         -*)
            project_github_ci_status::usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   [ $# -ne 0 ] && project_github_ci_status::usage "Superflous arguments \"$*\""

   local json

   if ! json="`rexekutor gh run list --json workflowName,startedAt,conclusion \
                         -L "${OPTION_COUNT}" \
                         -w "${OPTION_WORKFLOW_NAME}"`"
   then
      return 1
   fi

   project_github_ci_status::verify "${json}" "${OPTION_STALE_DIFF}"
}

#
# You can also use the function `call_with_flags`, which has been defined
# during mulle-boot. It lets you call 'project_github_ci_status::main'
# with MULLE_PROJECT_GITHUB_CI_STATUS_FLAGS interposed.
#
# call_with_flags "project_github_ci_status::main" "${MULLE_PROJECT_GITHUB_CI_STATUS_FLAGS}" "$@"

project_github_ci_status::main "$@"
