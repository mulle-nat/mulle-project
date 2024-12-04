#! /usr/bin/env mulle-bash
#! MULLE_BASHFUNCTIONS_VERSION=<|MULLE_BASHFUNCTIONS_VERSION|>
# shellcheck shell=bash
#
#
#  mulle-project-github-install-discord-webhook.sh
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


[ "${TRACE}" = 'YES' -o "${MULLE_PROJECT_GITHUB_INSTALL_DISCORD_WEBHOOK_TRACE}" = 'YES' ] \
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

project_github_install_discord_webhook::print_flags()
{
   echo "   -f          : force operation"
   echo "   -r <repo>   : github repository name"
   echo "   -u <name>   : github user name"
   echo "   -t <token>  : specify discord token"
   echo "   -s <id>     : discord server id"
   echo "   --url <url> : specify alternate webhook URL"

   ##
   ## ADD YOUR FLAGS DESCRIPTIONS HERE
   ##

   options_technical_flags_usage \
                "       : "
}


project_github_install_discord_webhook::usage()
{
   [ $# -ne 0 ] && log_error "$*"


   cat <<EOF >&2
Usage:
   mulle-project-github-install-discord-webhook [flags] [server] [token]

   Add a discord webhook to your github repository. Specify your discord
   server ID and the discord webhook token. Or use flags to finetune your
   request. The github user and repository will be determined from the
   current working directory, unless specified by flags.

   Tip: use -n -lx to see what will be used.

Flags:
EOF
   project_github_install_discord_webhook::print_flags | LC_ALL=C sort >&2

   exit 1
}


project_github_install_discord_webhook::main()
{
   #
   # simple option/flag handling
   #
   local OPTION_REPO
   local OPTION_USER
   local OPTION_URL
   local OPTION_TOKEN
   local OPTION_EVENTS
   local OPTION_SERVER
   local OPTION_HOOK_NAME="discord"

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
            project_github_install_discord_webhook::usage
         ;;

         -common-events)
            OPTION_EVENTS="issues issue_comment commit_comment \
create delete deployment deployment_status fork gollum label member milestone \
page_build project project_card project_column public pull_request \
pull_request_review pull_request_review_comment push release repository star \
status team_add watch workflow_run"
            ;;

         -s|-d|--discord-server)
            [ $# -eq 1 ] && project_github_install_discord_webhook::usage "missing argument to $1"
            shift

            OPTION_SERVER="$1"
         ;;

         -e|--event)
            [ $# -eq 1 ] && project_github_install_discord_webhook::usage "missing argument to $1"
            shift

            r_identifier "$1"
            r_concat "${OPTION_EVENTS}" "${RVAL}"
            OPTION_EVENTS="${RVAL}"
         ;;

         -r|--repo|--repository)
            [ $# -eq 1 ] && project_github_install_discord_webhook::usage "missing argument to $1"
            shift

            OPTION_REPO="$1"
         ;;

         -u|--user|--username|--user-name)
            [ $# -eq 1 ] && project_github_install_discord_webhook::usage "missing argument to $1"
            shift

            OPTION_USER="$1"
         ;;

         --hookname|--hook-name)
            [ $# -eq 1 ] && project_github_install_discord_webhook::usage "missing argument to $1"
            shift

            r_escaped_doublequotes "$1"
            OPTION_HOOK_NAME="${RVAL}"
         ;;


         -t|--token)
           [ $# -eq 1 ] && project_github_install_discord_webhook::usage "missing argument to $1"
            shift

            OPTION_TOKEN="$1"
         ;;

         --url|--webhook)
           [ $# -eq 1 ] && project_github_install_discord_webhook::usage "missing argument to $1"
            shift

            OPTION_URL="$1"
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         -*)
            project_github_install_discord_webhook::usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   if [ -z "${OPTION_SERVER}" ]
   then
      [ $# -eq 0 ] && project_github_install_discord_webhook::usage "Missing argument"
      OPTION_SERVER="$1"
      shift
   fi

   if [ -z "${OPTION_TOKEN}" ]
   then
      [ $# -eq 0 ] && project_github_install_discord_webhook::usage "Missing argument"
      OPTION_TOKEN="$1"
      shift
   fi
   [ $# -eq 0 ] || project_github_install_discord_webhook::usage "Superflous arguments $*"


   OPTION_URL="${OPTION_URL:-https://discord.com/api/webhooks/${OPTION_SERVER}/${OPTION_TOKEN}/github}"

   if [ -z "${OPTION_REPO}" ]
   then
      r_basename "${MULLE_VIRTUAL_ROOT:-${PWD}}"
      OPTION_REPO="${RVAL}"
   fi

   if [ -z "${OPTION_USER}" ]
   then
      r_dirname "${MULLE_VIRTUAL_ROOT:-${PWD}}"
      r_basename "${RVAL}"
      OPTION_USER="${RVAL}"
   fi

   # See: https://docs.github.com/de/rest/repos/webhooks?apiVersion=2022-11-28#create-a-repository-webhook

   set -- gh api --method POST
   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      set -- "$@" --verbose
   fi

   set -- "$@" -H "Accept: application/vnd.github+json" \
               -H "X-GitHub-Api-Version: 2022-11-28"

   set -- "$@" "/repos/${OPTION_USER}/${OPTION_REPO}/hooks"

   set -- "$@" -f "name=web" \
               -F "active=true"

   for event in ${OPTION_EVENTS:-"*"}
   do
      set -- "$@" -f "events[]=${event}"
   done

   set -- "$@" -f "config[url]=${OPTION_URL}" \
               -f "config[content_type]=json" \
               -f "config[insecure_ssl]=0"

   exekutor "$@"
}


#
# You can also use the function `call_with_flags`, which has been defined
# during mulle-boot. It lets you call 'project_github_install_discord_webhook::main'
# with MULLE_PROJECT_GITHUB_INSTALL_DISCORD_WEBHOOK_FLAGS interposed.
#
# call_with_flags "project_github_install_discord_webhook::main" "${MULLE_PROJECT_GITHUB_INSTALL_DISCORD_WEBHOOK_FLAGS}" "$@"

project_github_install_discord_webhook::main "$@"
