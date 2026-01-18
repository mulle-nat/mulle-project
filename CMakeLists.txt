cmake_minimum_required( VERSION 3.13...99.99)

project( mulle-project VERSION 4.5.0 LANGUAGES NONE)

option( MULLE_PROJECT_EMBED_BASHFUNCTIONS "Make some scripts independent from mulle-bash" ON)


set( TEMPLATES
README.md
formula-info.sh.template
generate-formula.sh.template
version-info.sh.template)


set( LIBRARY_SCRIPTS
src/mulle-project-git.sh
src/mulle-project-homebrew.sh
src/mulle-project-settings.sh
src/mulle-project-sourcetree-parser.sh
src/mulle-project-user-files-settings.sh
src/mulle-project-user-files.sh
src/mulle-project-version.sh
)


set( SCRIPTS
mulle-project-add-missing-branch-identifier
mulle-project-all
mulle-project-amalgamation-refresh
mulle-project-ci-settings
mulle-project-clib-json
mulle-project-cmake-graphviz
mulle-project-commit
mulle-project-debian
mulle-project-demo
mulle-project-distcheck
mulle-project-distribute
mulle-project-dockerhub
mulle-project-git-edit-comment.sh
mulle-project-github-ci-status.sh
mulle-project-github-description
mulle-project-github-install-discord-webhook.sh
mulle-project-github-rename-default-branch.sh
mulle-project-github-rerun-workflow
mulle-project-github-status
mulle-project-git-prerelease
mulle-project-git-submodules
mulle-project-infer-c
mulle-project-init
mulle-project-local-travis
mulle-project-mulle-clang-version
mulle-project-new-repo
mulle-project-objc-doctor
mulle-project-package-json
mulle-project-pacman-pkg
mulle-project-prerelease
mulle-project-properties-plist
mulle-project-redistribute
mulle-project-release-entry
mulle-project-releasenotes
mulle-project-reposfile
mulle-project-run-demos
mulle-project-sloppy-distribute
mulle-project-sourcetree-doctor
mulle-project-sourcetree-update-tags
mulle-project-squash-commits
mulle-project-squash-prerelease
mulle-project-tag
mulle-project-travis-ci-prerelease
mulle-project-untag
mulle-project-upgrade-cmake
mulle-project-version
mulle-project-version-extensions
mulle-project-versioncheck
mulle-strip-whitespace
)


set( EMBEDDING_SCRIPTS
mulle-clion-test
mulle-find-symbol
mulle-gitignore
mulle-project-all
mulle-replace
mulle-resolve-symlinks
mulle-shasum-url
)


if( MULLE_PROJECT_EMBED_BASHFUNCTIONS)
   foreach( SCRIPT ${EMBEDDING_SCRIPTS})
     add_custom_command(
       OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}"
       COMMAND mulle-bashfunctions embed < "${CMAKE_CURRENT_SOURCE_DIR}/${SCRIPT}" > "${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}"
       DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${SCRIPT}"
     )

     string( REPLACE "-" "_" TARGET_NAME "${SCRIPT}")

     add_custom_target(
       ${TARGET_NAME} ALL
       DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}"
     )

     INSTALL(
       FILES "${CMAKE_CURRENT_BINARY_DIR}/${SCRIPT}"
       PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
               GROUP_EXECUTE GROUP_READ
               WORLD_EXECUTE WORLD_READ
       DESTINATION "bin"
       COMPONENT "${TARGET_NAME}"
     )
   endforeach()
else()
   list( APPEND SCRIPTS ${EMBEDDING_SCRIPTS})
endif()


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
