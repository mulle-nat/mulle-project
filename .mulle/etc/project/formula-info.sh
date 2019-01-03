# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-project"      # your project/repository name
DESC="🤷🏾‍♀️ Manage project versions and releases"
LANGUAGE="bash"                # c,cpp, objc, bash ...
# NAME="${PROJECT}"        # formula filename without .rb extension

DEPENDENCIES='${MULLE_NAT_TAP}mulle-bashfunctions
${MULLE_SDE_TAP}mulle-make'


DEBIAN_DEPENDENCIES="mulle-bashfunctions, mulle-make"
