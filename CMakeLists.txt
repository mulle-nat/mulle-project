cmake_minimum_required (VERSION 3.0)

project( mulle-project NONE)

set( TEMPLATES
README.md
formula-info.sh.template
generate-formula.sh.template
version-info.sh.template)

set( LIBRARY_SCRIPTS
src/mulle-git.sh
src/mulle-homebrew.sh
src/mulle-publisher.sh
src/mulle-user-files.sh
src/mulle-version.sh
)


set( SCRIPTS
mulle-project-debian
mulle-project-distribute
mulle-project-env
mulle-project-releasenotes
mulle-project-untag
mulle-project-version
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
DESTINATION "libexec/mulle-project")

INSTALL( FILES ${TEMPLATES}
PERMISSIONS OWNER_WRITE OWNER_READ
            GROUP_READ
            WORLD_READ
DESTINATION "share/mulle-project")

######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
