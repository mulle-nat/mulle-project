cmake_minimum_required (VERSION 3.0)

# use C, because otherwise a CXX compiler is required
project( mulle-project C)

set( TEMPLATES
README.md
formula-info.sh.template
generate-formula.sh.template
version-info.sh.template)

set( LIBRARY_SCRIPTS
mulle-environment.sh
mulle-files.sh
mulle-git.sh
mulle-homebrew.sh
mulle-publisher.sh
mulle-version.sh
)

set( SCRIPTS
mulle-project-debian
mulle-project-env
mulle-project-init
mulle-project-release
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
