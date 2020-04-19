# mulle-sde Travis-CI Substitute

This docker container provides *local* [travis-ci](//travis-ci.org) like
testing for mulle-sde projects.
This is so much faster than doing a push to github and then waiting for travis
to spin up a VM and do its thing.


``` console
cd ~/src/MyProject
docker run -t -h "travis-ci.local" --volume "${PWD}:/mnt/project:ro" travis-ci-local --travis
```

> Depending on the docker installation, you might need to prefix `sudo` to
the docker commands.


## Create the image

You need to `docker build` the container "travis-ci-local" once before
running the tests in the directory containing `Dockerfile` and
`run-mulle-sde-project`. It depends on the container specified by the
`Dockerfile` in  [mulle-objc-developer](//github.com/mulle-objc/mulle-objc-developer),
so build it first:

```
docker build -t mulle-objc-developer https://raw.githubusercontent.com/mulle-objc/mulle-objc-developer/release/Dockerfile

cd mulle-project/travis
docker build -t travis-ci-local .
```

You can rebuild and use `--squash` after `-t`, to reduce image size.
(Newer docker versions only). After a new mulle-objc release you
should use docker build --pull to rebuild a new container.


At this point you should be able to get to the help usage of the
**`run-mulle-sde-project`** program on the docker:

```
sudo docker run -t travis-ci-local:latest help
```

## Mount project into docker

If there is no mulle-sde project properly mounted to `/mnt/project`
the `run-mulle-sde-project` program will complain and exit.
The docker container will never (unless you are reckless and use the --symlink
option) change your mounted project, so we can mount it `ro` (readonly)
(unless you use --symlink and feel even more reckless).

You can use `run-mulle-sde-project` to give you a shell inside your project.

```
docker run -t -h "travis-ci.local" --volume "${PWD}:/mnt/project:ro" travis-ci-local /bin/bash
```

With the `--env` parameter you will be inside the virtual environment:

```
docker run -t -h "travis-ci.local" --volume "${PWD}:/mnt/project:ro" travis-ci-local --env /bin/bash
```

> ####  Note
>
> The hostname `-h "travis-ci.local"`  is arbitrary. It can be left out.
>

### Copy

The default mode is copy. The project is copied internally from `/mnt/project`
to `~travis/travis-build/${PROJECT_NAME}`.

You will notice that the directories `addiction`, `dependency`, `kitchen`,
`stash` and `.mulle/var` will be missing. They are not copied, as their
contents may be only valid on the local host.


### Clone

In clone mode the copy is done via a `git clone`. Therefore you will only
get the committed files into the docker project.


### Symlink

In symlink there is no copy. This is obviously dangerous and should be
rarely useful.


## Executing commands

### Travis

You use the travis mode with the `--travis` flag. For this to work, your
project must have the `mulle-objc/travis` extension installed and upgraded
to the 0.11.0 version or later. Check this with `mulle-sde extension list`
and upgrade (clobbers!) `mulle-sde -f extension add mulle-objc/travis`.


### Shell

You can pass commands to `run-mulle-sde-project` and it will execute them
like a shell.

```
docker run -t -h "travis-ci.local" \
              --volume "${PWD}:/mnt/project:ro" \
              travis-ci-local \
              mulle-sde craft
```

You can also use the `--eval` option to get your command evaluated:

```
docker run -t -h "travis-ci.local" \
              --volume "${PWD}:/mnt/project:ro" \
              travis-ci-local \
              --eval  "mulle-sde test craft && mulle-sde test run --serial"
```



> #### Tip
>
> As run-mulle-sde-project uses [mulle-bashfunctions](//github.com/mulle-nat/mulle-bashfunctions),
> you can easily trace its actions with `-lx`:
>
> ```
> docker run -t -h "travis-ci.local" --volume "${PWD}:/mnt/project:ro" travis-ci-local -lx pwd
> ```

## Special features


### Upgrade mulle-sde in the docker

Mount your folder containing [mulle-sde](/github-com/mulle-sde) to `/mnt/sde`
and the container will install it automatically for you, overwriting the
already installed version.

### Export MULLE_FETCH_SEARCH_PATH into the docker

The folders mounted under `/mnt/search/...` will be used to create a
`MULLE_FETCH_SEARCH_PATH`. This can be passed to `mulle-sde` via the `-D`
option. The effect will be, that repositories are not fetched from the internet
unless they are missing locally.

### Tip

Use **mulle-project-local-travis** which does most of this setup for you.

