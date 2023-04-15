# shellcheck shell=bash
#
#   Copyright (c) 2020 Nat! - Mulle kybernetiK
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
MULLE_PROJECT_SOURCETREE_PARSER_SH='included'


# TODO: The hard coded nodetypes are a "blemish".
project::sourcetree_parser::get_dependency_address_nodetype_branch_tag_url()
{
   log_entry "project::sourcetree_parser::get_dependency_address_nodetype_branch_tag_url" "$@"

   #
   # TODO: be more clever with deduping
   #
   # don't push over technical flags, its too much and list
   # is readonly anyway
   # need also to ignore no-bequeath, to get everything needed for a build
   # maybe name no-bequeath no-link-bequeath ?
   #
   rexekutor mulle-sourcetree \
                  ${MULLE_SOURCETREE_FLAGS:-} \
                  -N \
               list --output-format raw \
                    --output-no-header \
                    --output-no-indent \
                    --marks dependency \
                    --force-format '%a;%n;%b;%t;%u\n' \
                    --nodetype tar \
                    --nodetype zip \
                    --nodetype git \
                    --nodetype clib \
                    "$@"
}


project::sourcetree_parser::is_matching_wildcards()
{
   log_entry "project::sourcetree_parser::is_matching_wildcards" "$@"

   local match_strings="$1"
   local string="$2"

   [ -z "${match_strings}" ] && return 0

   local match
   local rval

   shell_disable_glob ; IFS=$':'
   for match in ${match_strings}
   do
      # need noglob here for match
      shell_disable_glob ; IFS="${DEFAULT_IFS}"

      rval=0
      if [ "${match:0:1}" = '!' ]
      then
         match="${match:1}"
         rval=1
      fi

      case "${string}" in
         ${match})
            return $rval
         ;;
      esac
   done
   shell_enable_glob; IFS="${DEFAULT_IFS}"

   return 1
}


# output
#
#   local _address
#   local _nodetype
#   local _branch
#   local _url
#   local _host
#   local _user
#   local _repo
#   local _nodetype_identifier
#   local _nodetype_fallback
#   local _branch_identifier
#   local _branch_fallback
#   local _url_identifier
#   local _url_fallback
#   local _tag_identifier
#   local _tag_fallback

project::sourcetree_parser::parse_nodetype_branch_tag_url()
{
   log_entry "project::sourcetree_parser::parse_nodetype_branch_tag_url" "$@"

   local line="$1"

   log_setting "line                : >${line}<"

   [ -z "${line}" ] && _internal_fail "line is empty"

   _address="${line%%;*}"
   line=${line#*;}
   _nodetype="${line%%;*}"
   line=${line#*;}
   _branch="${line%%;*}"
   line=${line#*;}
   _tag="${line%%;*}"
   line=${line#*;}
   _url="${line%%;*}"

   log_setting "address             : ${_address}"
   log_setting "nodetype            : ${_nodetype}"
   log_setting "branch              : ${_branch}"
   log_setting "tag                 : ${_tag}"
   log_setting "url                 : ${_url}"

   [ -z "${_address}" ] && _internal_fail "address is empty"

   local s

   # get override identifier from _nodetype
   s="${_nodetype}"
   s="${s#\$\{}"
   s="${s%\}}"

   case "${_nodetype}" in
      \$\{*':-'*\})
         _nodetype_identifier="${s%\:\-*}"
         _nodetype_fallback="${s##*\:\-}"
      ;;

      \$\{*\})
         _nodetype_identifier="${s}"
      ;;

      *)
         _nodetype_fallback="${_nodetype}"
      ;;
   esac

   # get override identifier from _branch
   s="${_branch}"
   s="${s#\$\{}"
   s="${s%\}}"

   case "${_branch}" in
      \$\{*':-'*\})
         _branch_identifier="${s%\:\-*}"
         _branch_fallback="${s##*\:\-}"
      ;;

      \$\{*\})
         _branch_identifier="${s}"
      ;;

      *)
         _branch_fallback="${_branch}"
      ;;
   esac

   # get override identifier from _tag
   s="${_tag}"
   s="${s#\$\{}"
   s="${s%\}}"

   case "${_tag}" in
      \$\{*':-'*\})
         _tag_identifier="${s%\:\-*}"
         _tag_fallback="${s##*\:\-}"
      ;;

      \$\{*\})
         _tag_identifier="${s}"
      ;;

      *)
         _tag_fallback="${_tag}"
      ;;
   esac

   # get override identifier and _url_fallback from _url
   s="${_url}"
   s="${s#\$\{}"
   s="${s%\}}"

   case "${_url}" in
      \$\{*':-'*\})
         _url_identifier="${s%\:\-*}"
         _url_fallback="${s##*\:\-}"
      ;;

      \$\{*\})
         _url_identifier="${s}"
      ;;

      *)
         _url_fallback="${_url}"
      ;;
   esac

   # get _host
   # get _user
   # get _repo
   s="${_url_fallback}"

   case "${s}" in
      *://*)
         s="${s#*://}"     # remove scheme
         _host="${s%%/*}"   # get _host
         s="${s#${_host}}"  # remove _host
         s="${s##/}"       # remove slash
         _user="${s%%/*}"   # get _user
         s="${s#${_user}}"  # remove _user
         s="${s##/}"       # remove slash
         _repo="${s%%/*}"   # get _repo (that's all we want)
      ;;

      *:*)
         s="${s#*:}"        # remove scheme
         _host=""
         _user="${s%%/*}"   # get _user
         s="${s#${_user}}"  # remove _user
         s="${s##/}"       # remove slash
         _repo="${s%%/*}"   # get _repo (that's all we want)
      ;;

      *)
         _host=""
         _user=""
         _repo="${s}"   # get _repo (that's all we want)
      ;;
   esac

   log_setting "branch_fallback     : ${_branch_fallback}"
   log_setting "branch_identifier   : ${_branch_identifier}"
   log_setting "nodetype_fallback   : ${_nodetype_fallback}"
   log_setting "nodetype_identifier : ${_nodetype_identifier}"
   log_setting "url_fallback        : ${_url_fallback}"
   log_setting "url_identifier      : ${_url_identifier}"
   log_setting "host                : ${_host}"
   log_setting "user                : ${_user}"
   log_setting "repo                : ${_repo}"

   return 0
   # don't need the other stuff so far...
}
