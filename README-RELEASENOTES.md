# mulle-project-releasenotes

You are ready to tag your program. You keep your release-notes in a file
`RELEASENOTES.md` Once they have been written, you will tag your project.
It is assumed that the version number has been set correctly already and that
it can be retrieved with  `mulle-project-version`. That makes it all a
little easier.


#### 1. Check that the version number is correct

```
mulle-project-version
```

#### 2. Check generated content

Your commit comments contain the release-notes, prefixed
by '* '.  Example:

```
* this is a release-note
but this is not
```

Check how your new release-notes would look like with
`mulle-project-releasenotes`

If you're missing something, check the raw comments with
`mulle-project-releasenotes --unfiltered` for lines that don't have the
prefix '* '.

> Hint: If you messed up and some lines aren't prefixed, continue to use
> the `--unfiltered` in the next commands and then hand-edit the result after step #4.

Did you still expect to see more output ? Try
`mulle-project-releasenotes --missing --input RELEASENOTES.md`
to combine commit logs from comments of previous tags.


#### 3. Check proper placement

Check that the new release-notes are properly prepended to the old ones with
`mulle-project-releasenotes --input RELEASENOTES.md`

If there are already old ones from a previous run, and you don't have
important manual edits then overwrite them with `mulle-project-releasenotes
-f --input RELEASENOTES.md`


#### 4. Update releasenotes

Write the update `RELEASENOTES.md` file with (add `-f` if needed):

```
mulle-project-releasenotes "RELEASENOTES.md"
```

> Hint: You can _seamlessly_ commit the RELEASENOTES.md  into the previous
> commit with `git commit --amend --no-edit "RELEASENOTES.md"`



