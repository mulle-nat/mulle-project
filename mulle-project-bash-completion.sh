# Bash completion for mulle-project
# shellcheck shell=bash

_mulle_project_complete()
{
    local cur prev words cword
    _init_completion || return

    local commands=(
        "libexec-dir"
        "share-dir"
        "path"
        "version"
        "help"
    )

    local global_flags=(
        "-h"
        "--help"
        "--version"
        "--verbose"
        "--debug"
        "--trace"
    )

    local subcommands=(
        "add-missing-branch-identifier"
        "ai"
        "all"
        "amalgamation-refresh"
        "bash-completion"
        "bash-usage"
        "choco-nuspec"
        "ci-settings"
        "clib-json"
        "cmake-graphviz"
        "commit"
        "debian"
        "demo"
        "distcheck"
        "distribute"
        "dockerhub"
        "extension-versions"
        "git-prerelease"
        "git-submodules"
        "github-description"
        "github-rerun-workflow"
        "github-status"
        "infer-c"
        "init"
        "local-travis"
        "mulle-clang-version"
        "new-repo"
        "package-json"
        "pacman-pkg"
        "prerelease"
        "properties-plist"
        "redistribute"
        "release-entry"
        "releasenotes"
        "reposfile"
        "run-demos"
        "sloppy-distribute"
        "sourcetree-doctor"
        "sourcetree-update-tags"
        "squash-commits"
        "squash-prerelease"
        "tag"
        "travis-ci-prerelease"
        "untag"
        "upgrade-cmake"
        "version"
        "versioncheck"
        "version-extensions"
    )

    if [[ $cword -eq 1 ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "${global_flags[*]}" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "${commands[*]} ${subcommands[*]}" -- "$cur") )
        fi
        return 0
    fi

    case "${words[1]}" in
        libexec-dir|share-dir|path|version|help)
            return 0
            ;;
        
        ai)
            local ai_flags="--model --plugin --help"
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "$ai_flags" -- "$cur") )
            fi
            return 0
            ;;
        
        bash-completion)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help" -- "$cur") )
            fi
            return 0
            ;;
        
        tag|untag)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help" -- "$cur") )
            elif [[ -d .git ]]; then
                local tags=$(git tag 2>/dev/null)
                COMPREPLY=( $(compgen -W "$tags" -- "$cur") )
            fi
            return 0
            ;;
        
        commit)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help --message -m" -- "$cur") )
            fi
            return 0
            ;;
        
        distribute|redistribute|sloppy-distribute)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help --force --no-test" -- "$cur") )
            fi
            return 0
            ;;
        
        github-status|github-description|github-rerun-workflow)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help" -- "$cur") )
            fi
            return 0
            ;;
        
        init)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help --language --type" -- "$cur") )
            fi
            return 0
            ;;
        
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--help -h" -- "$cur") )
            fi
            return 0
            ;;
    esac
}

complete -F _mulle_project_complete mulle-project
