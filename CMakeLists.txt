cmake_minimum_required (VERSION 3.0)

project( mulle-homebrew)

set( TEMPLATES
README.md
release.sh.template
version-info.sh.template
formula-info.sh.template
)

set( LIBRARY_SCRIPTS
mulle-environment.sh
mulle-files.sh
mulle-git.sh
mulle-homebrew.sh
mulle-version.sh
)

set( SCRIPTS
mulle-homebrew-debian
mulle-homebrew-env
mulle-homebrew-version
mulle-homebrew-init
mulle-homebrew-untag
)


INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")

INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-homebrew")

INSTALL( FILES ${TEMPLATES}
PERMISSIONS OWNER_WRITE OWNER_READ
            GROUP_READ
            WORLD_READ
DESTINATION "share/mulle-homebrew")
