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
src/mulle-sourcetree-parser.sh
src/mulle-user-files-settings.sh
src/mulle-user-files.sh
src/mulle-version.sh
)


set( SCRIPTS
mulle-project-add-missing-branch-identifier
mulle-project-all
mulle-project-ci-settings
mulle-project-cmake-graphviz
mulle-project-debian
mulle-project-distcheck
mulle-project-distribute
mulle-project-env
mulle-project-extension-versions
mulle-project-git-prerelease
mulle-project-git-submodules
mulle-project-init
mulle-project-local-travis
mulle-project-package-json
mulle-project-prerelease
mulle-project-redistribute
mulle-project-release-entry
mulle-project-releasenotes
mulle-project-sloppy-distribute
mulle-project-sourcetree-update-tags
mulle-project-tag
mulle-project-travis-ci-prerelease
mulle-project-untag
mulle-project-version
mulle-project-versioncheck
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
