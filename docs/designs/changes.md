<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Changes
@design changes=v1
@cites {
    conformance=v1, text=v1, files=v1, data-forms=v1, ontology=v1,
    gitdoc/git, gitdoc/gitrepository-layout, gitdoc/git-worktree,
    gitdoc/gitglossary, gitdoc/gitdatamodel, gitdoc/gitformat-loose,
    gitdoc/gitformat-pack, gitdoc/gitformat-commit-graph,
    gitdoc/git-commit-tree, gitdoc/git-pack-refs, gitdoc/git-reflog,
    gitdoc/git-update-ref, gitdoc/reftable, gitdoc/gitformat-index,
    gitdoc/git-config, gitdoc/gitignore, gitdoc/git-check-ref-format,
    gitdoc/git-fetch, gitdoc/git-push, gitdoc/git-remote-ext,
    gitdoc/githooks, gitdoc/gitattributes, posix/2024,
}
Git repositories store commits, refs, reflogs, and working trees from which programs read commit metadata, trees of files, commit changes, landing commits, and line-level diffs without modifying the repository or running repository-supplied programs.

A git repository holds commits in its object databases, stores refs and
reflogs, and maintains zero or more working trees. Each commit names its
parent commits, carries a raw message, and points to a git tree object.
Comparing a commit with the default branch identifies its commit change,
its change base, and the line hunks between its base tree and its own
tree.

## Git repositories and commits

@spec repository=v1

A git repository stores commits in its object databases and holds
configuration and zero or more working trees. Each commit names its
parent commits in order and carries a raw message byte sequence. A
program reads values from a git repository in a repository read.

### Definitions

#### Git directory

@term git-directory=v1
@cites {
    gitdoc/git, gitdoc/gitrepository-layout, gitdoc/git-worktree,
    gitdoc/git-config, files#directory=v1,
}

The **git directory** of a git repository is the `directory` that holds
the files of that git repository shared by its working trees:
`$GIT_COMMON_DIR`, or `$GIT_DIR` when no common directory is set, as
`git`, `gitrepository-layout`, and `git-worktree` define those paths
(for example, the `.git` directory of a main working tree). A git
repository uses version 0 or version 1 of the repository format defined
by `gitrepository-layout`. The ref storage format of a git repository,
`files` or `reftable`, is the format that `extensions.refStorage` names
under `git-config`.

#### Working tree

@term working-tree=v1
@cites {
    gitdoc/git, gitdoc/gitrepository-layout, gitdoc/git-worktree,
    gitdoc/gitformat-index, posix/2024,
    files#{directory=v1, directory-tree=v1},
    #git-directory=v1,
}

A **working tree** of a git repository is its main working tree or one
of its linked working trees, as `git-worktree` defines them. A working
tree has a **root directory**, which is the root of the `directory-tree`
of files that a person edits, and a **directory of the working tree**,
which holds the `HEAD` of that working tree:

- For the main working tree, the directory of the working tree is the
  `git-directory`.
- For each linked working tree, the directory of the working tree is its
  directory inside the `worktrees` directory of the `git-directory`, as
  `git-worktree` and `gitrepository-layout` define linked working trees.

**Git's index** of a working tree is the file `index` in the directory
of that working tree, with one exception: for the working tree selected
by the environment in which the program started (through `GIT_DIR` and
`GIT_WORK_TREE` or the starting directory, as `git` defines it), when
`GIT_INDEX_FILE` is set in that environment, git's index is the file
that `GIT_INDEX_FILE` names. Git's index uses version 2, 3, or 4 of the
format defined by `gitformat-index`, together with any auxiliary files
that format names (such as the shared index of a split index).

The **files of a working tree** are the files of the `directory-tree`
whose root is the root directory of that working tree, excluding the
file of the directory entry `.git` of that root directory and, when that
file is a `directory`, the files of the `directory-tree` rooted at that
`.git` directory.

#### Git configuration

@term git-configuration=v1
@cites {
    gitdoc/git-config, posix/2024, files#file-kind=v1,
    #{git-directory=v1, working-tree=v1},
}

The **git configuration** of a `working-tree` is the set of settings,
each with its values in order, defined by `git-config` for that working
tree in the environment in which the program started. The **git
configuration** of a git repository is the set of settings defined in
the same way for its `git-directory` with no working tree.

The **files of a git configuration** are all of these files, following
symbolic links (`file-kind`) on each pathname and regardless of whether
a file exists at that pathname:

- each file at a pathname from which `git-config` reads settings for
  that git configuration; and
- recursively, each file named by an include directive in a file of that
  git configuration, whether or not the condition of that include holds.

#### Commit

@term commit=v1
@cites {
    gitdoc/git, gitdoc/gitrepository-layout, gitdoc/gitglossary,
    gitdoc/gitdatamodel, gitdoc/gitformat-loose, gitdoc/gitformat-pack,
    posix/2024, conformance#input=v1, text#byte-sequence=v1,
    files#directory=v1, #git-directory=v1,
}

As an `input`, a git repository has as parts the git objects named by
object names within it, such as the git objects to which its refs point
and the parent commits and git tree objects named by its commits. A
valid git repository, such as a partial clone, can lack such a git
object.

The **object databases** of a git repository are the `objects` directory
of its `git-directory` and, recursively, each `directory` named by the
alternates of one of its object databases, as `gitrepository-layout`
defines object databases and alternates. For the git repository selected
by the environment in which the program started (through `GIT_DIR` or
the starting directory, as `git` defines it):

- when `GIT_OBJECT_DIRECTORY` is set in that environment, the directory
  it names replaces the `objects` directory; and
- each directory named by `GIT_ALTERNATE_OBJECT_DIRECTORIES` in that
  environment is also an object database.

A git repository **holds** a git object when one of its object databases
holds that git object as a loose object (`gitformat-loose`) or in a pack
of version 2 or 3 with a pack index of version 1 or 2
(`gitformat-pack`).

A **commit** of a git repository is a commit object (`gitglossary`) that
the git repository holds. Each commit has these parts as `gitdatamodel`
defines them:

- one **git tree object**;
- its **parents**, in the order the commit object names them (the first
  of which is its **first parent**); and
- its **message**, which is a `byte-sequence`.

A commit named by the `shallow` file of the `git-directory` has no
parents, as `gitglossary` and `gitrepository-layout` define shallow
repositories and `shallow`. When a commit is not named by `shallow` and
its commit object names, as a parent, a held git object that is not a
commit object, the parents of that commit are not specified.

The content of a blob, the entries of a git tree object, and the git
tree object, message, and (apart from the `shallow` rule) parents of a
commit are those held by the git object itself. A **replacement ref** is
a ref whose name starts with `refs/replace/`. Replacement refs have no
effect on blobs, git tree objects, or commits.

#### Message text

@term message-text=v1
@cites {
    gitdoc/git-commit-tree,
    text#{text=v1, valid-utf-8=v1, utf-8-text=v1},
    #commit=v1,
}

The **message text** of a `commit` is the `utf-8-text` of the commit's
message byte sequence when that byte sequence is `valid-utf-8`. When the
message byte sequence is not `valid-utf-8`, the commit's message has no
text. The `encoding` header of the commit object (`git-commit-tree`) has
no effect on the message text.

#### Shallow commit

@term shallow-commit=v1
@cites {
    gitdoc/gitrepository-layout, gitdoc/gitglossary,
    #{git-directory=v1, commit=v1},
}

A **shallow commit** of a git repository is a `commit` of that git
repository named by the `shallow` file of its `git-directory`, as
`gitglossary` and `gitrepository-layout` define shallow repositories and
`shallow`.

#### Repository file

@term repository-file=v1
@cites {
    gitdoc/git-config, gitdoc/gitformat-index, gitdoc/gitattributes,
    posix/2024,
    files#{directory=v1, directory-tree=v1, file-kind=v1},
    #{
        git-directory=v1, working-tree=v1, git-configuration=v1,
        commit=v1,
    },
}

The **repository files** of a git repository are all of these files:

- the files of the `directory-tree` rooted at its `git-directory`, the
  directory tree rooted at each of its object databases (`commit`), and
  the directory tree rooted at the root directory of each of its
  `working-tree`s;
- recursively, every file reached through a symbolic link (`file-kind`)
  in the directory tree of its `git-directory` or of an object database,
  together with the files of the directory tree rooted at each such
  target that is a `directory`;
- the files of the `git-configuration` of the git repository and of each
  of its working trees;
- for each working tree, the excludes file named by `core.excludesFile`
  in that working tree's git configuration (or its default under
  `git-config` in the starting environment when unset), following
  symbolic links on its pathname;
- git's index of each working tree and any auxiliary files named by
  `gitformat-index`, following symbolic links on their pathnames; and
- the git attributes files that `gitattributes` specifies for the git
  repository and for each working tree other than `.gitattributes` files
  inside working-tree directories, following symbolic links on their
  pathnames.

#### Remote transfer

@term remote-transfer=v1
@cites {
    gitdoc/git-config, gitdoc/git-fetch, gitdoc/git-push,
    gitdoc/gitglossary, #git-configuration=v1,
}

A **remote** of a git repository is a name `r` for which the
`git-configuration` of the git repository defines a value for
`remote.<name>.url` with `r` for `<name>`. The **addresses** of remote
`r` for a fetch and for a push are the addresses that `git-config`
derives from `remote.<name>.url` and `remote.<name>.pushurl` (with `r`
for `<name>`) after applying rewrites from `url.<base>.insteadOf` and
`url.<base>.pushInsteadOf`.

A **fetch** from a remote is a transfer of git objects, refs
(`gitglossary`), or both into the git repository from the git repository
at an address of that remote for a fetch, as `git-fetch` defines
fetches. A **push** to a remote is a transfer of git objects, refs, or
both from the git repository into the git repository at an address of
that remote for a push, as `git-push` defines pushes.

#### Repository read

@term repository-read=v1
@cites {
    gitdoc/gitglossary, posix/2024,
    conformance#{input=v1, dependence=v1, report-missing-parts=v1},
    files#read-byte=v1,
    #{
        working-tree=v1, commit=v1, repository-file=v1,
        remote-transfer=v1,
    },
}

A **repository read** is an operation in which a program reads, from a
git repository or from one of its `working-tree`s, one or more values
defined by `changes` (such as a `commit`, its parents, or a ref per
`gitglossary`) to return or use them. A standalone fetch, a push
(`remote-transfer`), or a ref update (together with any git objects
written for that update) is not a repository read.

An object-only fetch into the git repository that transfers no ref and
that the program performs (directly or through another program) during a
repository read—such as fetching missing git objects in a partial
clone—is part of that repository read. No fetch that transfers a ref, no
push, and no ref update is part of a repository read.

When a result required in a repository read needs (`dependence`) a git
object that the git repository does not hold, and no fetch that is part
of that repository read brings that git object into an object database
of the git repository, that git object is a part that the valid git
repository lacks (`input`, `report-missing-parts`).

A repository read lasts from the first time the program (directly or
through another program) reads bytes (`read-byte`) or uses a pathname
(`posix/2024`) to access or look up a `repository-file` for that read
until the last time the program does so for that read. Actions after
that last access, such as returning the computed result, occur outside
the read's duration. The returned value still counts as returned in that
repository read.

#### Undisturbed repository read

@term undisturbed-read=v1
@cites {
    posix/2024, gitdoc/gitglossary, gitdoc/gitrepository-layout,
    gitdoc/gitformat-loose, gitdoc/gitformat-pack,
    gitdoc/gitformat-commit-graph, gitdoc/gitformat-index,
    files#{
        directory=v1, directory-tree=v1, file-kind=v1, read-byte=v1,
    },
    #{
        git-directory=v1, working-tree=v1, commit=v1,
        repository-file=v1, remote-transfer=v1, repository-read=v1,
    },
}

To **change** a file is to alter the content of a regular file, the
directory entries of a `directory`, the reference of a symbolic link, or
the data of a file of another kind (`file-kind`). Reading bytes from a
file changes no file.

A `repository-read` is **undisturbed** when no process—including the
program making the read—performs either of these actions during the
read, except in an **own change** of that read on a file that is not a
file of a `working-tree`:

1. creates, deletes, or changes a `repository-file` from which the
   program (directly or through another program) reads bytes
   (`read-byte`) during the read; or
2. changes which file a pathname (`posix/2024`) resolves to, or whether
   that pathname resolves to a file, for a pathname that the program
   (directly or through another program) uses during the read to access
   or look up a `repository-file`.

An **own change** of a `repository-read` is the creation, deletion, or
change of a file by the program (directly or through another program)
during that read, when that file is one of these:

1. in an object database (`commit`), a loose object file
   (`gitformat-loose`) or a pack file (`gitformat-pack`) that the
   program creates during the read, a file specific to such a pack (such
   as its pack index), or a directory in that object database's
   `directory-tree`;
2. during a fetch (`remote-transfer`) that is part of the read, the
   commit-graph file `info/commit-graph`, the directory
   `info/commit-graphs`, or a file inside `info/commit-graphs` in an
   object database (`gitformat-commit-graph`);
3. git's index of a `working-tree`, an auxiliary file named by
   `gitformat-index`, or the directory holding that index, provided that
   the set of byte paths for which git's index has an entry, or has a
   sparse directory entry that summarizes the path (`gitformat-index`),
   is the same before and after the change; or
4. a temporary file or lock file created by the program in a directory
   of items 1, 2, or 3 that the program deletes or renames to a file of
   items 1, 2, or 3.

A change to a directory of items 1, 2, or 3 counts as an own change only
when every directory entry that the change creates, deletes, or changes
names a non-directory file of items 1 to 4 or a directory created by the
program during the read. No creation, deletion, or change of a file that
holds a ref or reflog (`gitglossary`, `gitrepository-layout`), of
`FETCH_HEAD` or `shallow` in the `git-directory`, or of
`info/alternates` in an object database (even as a temporary file of
item 4) counts as an own change.

### Returning commit parents

@req give-commit-parents=v1
@cites {
    conformance#conforming-program=v1,
    #{commit=v1, repository-read=v1, undisturbed-read=v1},
}

When returning the parents of a `commit` of a git repository in an
undisturbed `repository-read` (`undisturbed-read`), a conforming program
must return the parents of that commit in their order, with no missing
or extra commits.

### Returning message texts

@req give-message-texts=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #{
        commit=v1, message-text=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When returning the `message-text` of a `commit` of a git repository, or
that the message has no text, in an undisturbed `repository-read`
(`undisturbed-read`), a conforming program must return that `text` when
the commit's message has a text, and must return that the message has no
text when the commit's message has no text.

### Keeping repositories unchanged

@req keep-repositories-unchanged=v1
@cites {
    posix/2024,
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{repository-file=v1, repository-read=v1, undisturbed-read=v1},
}

During a `repository-read`, a conforming program (directly or through
any program it uses) must never create, delete, or change any
`repository-file` of the git repository (as `undisturbed-read` defines
changing a file), except in an own change of that read
(`undisturbed-read`) or to a file already open in the program's process
when that process started (`posix/2024`), such as standard output.

### Reading only repository files

@req read-only-repository-files=v1
@cites {
    posix/2024,
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{file-kind=v1, read-byte=v1},
    #{repository-file=v1, remote-transfer=v1, repository-read=v1},
}

During a `repository-read`, a conforming program (directly or through
any program it uses) must read bytes (`read-byte`) only from these
sources:

- the `repository-file`s of the git repository and symbolic links
  (`file-kind`) on the pathnames (`posix/2024`) used to reach them;
- files that the system or the libraries of a program read to run that
  program, and installed files of the conforming program or of a program
  that it uses (such as executables, libraries, modules, and data);
- files that the conforming program creates in the execution that makes
  the read;
- pipes between the conforming program and a program that it uses, and
  files and pipes that were open in its process when that process
  started, such as standard input; and
- in a fetch from a remote (`remote-transfer`) that is part of that
  repository read, the git repository at that remote's fetch address,
  the connections reaching it, and files that a program making that
  fetch reads under its own setup (such as SSH client configuration, SSH
  keys, or a credential helper store).

### Gaining no repository privileges

@req gain-no-repository-privileges=v1
@cites {
    posix/2024,
    conformance#{conforming-program=v1, safety-obligation=v1},
    #repository-read=v1,
}

During a `repository-read`, a conforming program must use only the
POSIX.1-2024 permissions and appropriate privileges that its process
holds without a change by the program, and must never gain or use
additional permissions or privileges by changing its user IDs, group
IDs, or privileges, or through another process acting for it.

### Running no configured programs

@req run-no-configured-programs=v1
@cites {
    posix/2024, gitdoc/githooks, gitdoc/git-config, gitdoc/git-fetch,
    gitdoc/git-remote-ext,
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{directory-tree=v1, file-kind=v1},
    #{
        git-directory=v1, working-tree=v1, git-configuration=v1,
        remote-transfer=v1, repository-read=v1,
    },
}

In any execution that performs a `repository-read`, a fetch, or a push
(`remote-transfer`), let an **accessed repository** be any git
repository that the program (directly or through any program it uses)
reads, fetches from or into, or pushes from or to in that execution. A
configuration value **comes from a git repository** when it appears in
the `config` file of that repository's `git-directory`, in a
`config.worktree` file in the directory of one of its `working-tree`s,
or recursively in any file included by either under `git-config`.

A conforming program (directly or through any program it uses) must
never run—as a process, as native code loaded in its process, through a
shell or another program (`posix/2024`), or as a command passed to a
remote or local server—any of these:

- any git hook (`githooks`);
- any executable or loadable file in the `directory-tree` of an accessed
  repository's `git-directory` or in the files of any `working-tree` of
  an accessed repository, or reached through a symbolic link
  (`file-kind`) in either, other than a file that the system loads to
  start the conforming program or an installed file of the conforming
  program (such as its executable, a library, or a module, and not a
  separate program such as `git` or `ssh` installed on its own); or
- any program or command named, supplied, or triggered by the
  `git-configuration` of an accessed repository or of any of its working
  trees, such as a filter, `core.fsmonitor`, `core.sshCommand`, or an
  `ext::<command>` address (`git-remote-ext`).

During a fetch from or push to a remote (`remote-transfer`), a
conforming program may still run programs that perform that fetch or
push as configured outside the accessed repositories (whose
configuration values do not come from an accessed repository and whose
executables lie outside the accessed repositories, such as `ssh` or a
credential helper), together with the transport program that an address
form other than `ext::<command>` selects (`git-fetch`), such as `ssh` or
a remote helper, and the command that the address form sends to the
remote, such as `git-upload-pack` with the address path. In such a fetch
or push, the program must still never run any git hook, any file of an
accessed repository (other than a file that the system loads to start
the conforming program or an installed file of the conforming program),
any `ext::<command>` address, or any program or command that a value
coming from an accessed repository names or supplies, other than that
transport program and remote command selected by an address form other
than `ext::<command>`.

What a remote server runs under its own setup (such as a server-side
hook on a remote host) does not count as a program run by the conforming
program, except for what a local-path or `file://` server (`git-fetch`)
runs during a fetch that is part of a `repository-read`. Sandboxed code
that runs isolated from the host process (such as WebAssembly) does not
count as running a program under this requirement.

@example During a [fetch](sinter:#remote-transfer=v1) from a remote, a
program can run an `ssh` client, a `core.sshCommand` value, or a
credential helper that user configuration
([git-config](sinter:gitdoc/git-config)) sets, and not the accessed
repository. By contrast, the program refuses a `core.sshCommand` value
set in the accessed repository's
[git directory](sinter:#git-directory=v1) file `config` and refuses any
`ext::<command>` address
([git-remote-ext](sinter:gitdoc/git-remote-ext)).

### Following no working-tree links

@req follow-no-working-tree-links=v1
@cites {
    gitdoc/gitrepository-layout, gitdoc/git-config,
    gitdoc/gitattributes,
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{directory=v1, file-kind=v1},
    #{
        git-directory=v1, working-tree=v1, git-configuration=v1,
        remote-transfer=v1, repository-read=v1,
    },
}

During a `repository-read`, a conforming program (directly or through
any program it uses) must never follow a symbolic link (`file-kind`)
that is a file of a `working-tree` of the git repository, or resolve any
file through its reference, except when that symbolic link lies on the
pathname to one of these:

- a file of the `git-configuration` of the git repository or of a
  working tree;
- the `info/exclude` file of the `git-directory`
  (`gitrepository-layout`);
- the excludes file named by `core.excludesFile` in a working tree's git
  configuration (or its default under `git-config` in the starting
  environment when unset);
- a git attributes file (`gitattributes`) other than a `.gitattributes`
  file inside a `working-tree` `directory`;
- a file that the system loads to start the conforming program, or an
  installed file of the conforming program (such as its executable, a
  library, a module, or a data file); or
- in a fetch (`remote-transfer`) that is part of that repository read, a
  file that a program making that fetch reads under its own setup.

### Test vectors

Test vectors for `repository` live in
[changes.test-vectors.jsonl](changes.test-vectors.jsonl). No group uses
`needs`.

#### Parent vectors

@schema parent-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    #{
        commit=v1, shallow-commit=v1, repository-read=v1,
        undisturbed-read=v1, give-commit-parents=v1,
    },
}

`parent-vector` is a `group-schema` for group `parents` and tests
`give-commit-parents`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector stands for an undisturbed
`repository-read` (`undisturbed-read`) of a git repository holding the
subject `commit` and every commit named in `input.named` (each
identified by a short commit name such as `"a"`), and no other commit.

| field | type | meaning |
|---|---|---|
| `input.named` | array of strings | short commit names of the parents listed by the commit object, in order |
| `input.shallow` | boolean | `true` when the subject commit is a `shallow-commit`, `false` otherwise |
| `values.parents` | array of strings | expected ordered parents of the subject commit, as short commit names (`[]` when none) |

@example Sample lines testing
[give-commit-parents](sinter:#give-commit-parents=v1) for ordered
parents of a [commit](sinter:#commit=v1) and for a
[shallow commit](sinter:#shallow-commit=v1):

```json
{"form":"#parent-vector=v1","group":"parents","input":{"named":["a","b"],"shallow":false},"note":"the first parent comes first","values":{"parents":["a","b"]}}
{"form":"#parent-vector=v1","group":"parents","input":{"named":["a"],"shallow":true},"note":"the file `shallow` names the commit","values":{"parents":[]}}
```

#### Message text vectors

@schema message-text-vector=v1
@cites {
    gitdoc/git-commit-tree,
    data-forms#{
        hex-text=v1, group-schema=v1, vector-line=v1, vector-meaning=v1,
    },
    text#{text=v1, byte-sequence=v1, utf-8-encoding=v1},
    #{
        commit=v1, message-text=v1, repository-read=v1,
        undisturbed-read=v1, give-message-texts=v1,
    },
}

`message-text-vector` is a `group-schema` for group `message-texts` and
tests `give-message-texts`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector stands for an undisturbed
`repository-read` (`undisturbed-read`) of a git repository holding the
subject `commit` and no other commit.

| field | type | meaning |
|---|---|---|
| `input.message` | string or `{"bytes": string}` | commit message `byte-sequence`: either a JSON string (representing its `utf-8-encoding`) or an object with single member `bytes` holding its `hex-text` |
| `input.encoding` | string (optional) | value of the commit object's `encoding` header (`git-commit-tree`); present when and only when the commit object has that header |
| `values.text` | string (optional) | expected `message-text` (`text`) when the message has a text; absent (`values` is `{}`) when the message has no text |

@example Sample lines testing
[give-message-texts](sinter:#give-message-texts=v1) for invalid
([hex-text](sinter:data-forms#hex-text=v1)) and valid UTF-8
[message text](sinter:#message-text=v1) inputs with an ignored
`encoding` header ([git-commit-tree](sinter:gitdoc/git-commit-tree)):

```json
{"form":"#message-text-vector=v1","group":"message-texts","input":{"encoding":"ISO-8859-1","message":{"bytes":"636166e90a"}},"note":"the bytes are not valid UTF-8, whatever the header `encoding`","values":{}}
{"form":"#message-text-vector=v1","group":"message-texts","input":{"encoding":"ISO-8859-1","message":"café\n"},"note":"the header `encoding` has no effect","values":{"text":"café\n"}}
```

## Refs, branches, and reflogs

@spec refs=v1

Git refs point to commits and other git objects directly or through
symbolic refs, and each working tree records its current branch, or a
detached commit, in `HEAD`. Local reflogs record updates to refs, while
remote fetch refspecs map remote ref names to local ref names. A
configured branch name identifies the repository's default branch.

### Parameters

@schema default-branch-name=v1
@cites {
    ontology#{default-branch=v1, parameter=v1},
    text#text=v1,
    #branch-name=v1,
}

The `parameter` `default-branch-name` names the `default-branch` of a
git repository. A binding of `default-branch-name` is a `text`. A
binding meets the schema `default-branch-name` when, and only when, the
binding is a `branch-name`. Otherwise, the binding is invalid.

### Definitions

#### Ref name

@term ref-name=v1
@cites {
    gitdoc/git-check-ref-format,
    gitdoc/gitglossary,
    text#text=v1,
}

A **ref name** is a `text` that meets both of these conditions:

- The text meets the rules of `git-check-ref-format` for ref names,
  except for the rule that a ref name contains `/`.
- The text starts with `refs/` or is a root name.

A **root name** is a name of a ref in the root of the ref hierarchy that
meets the `gitglossary` rules for such names (such as `HEAD` or
`ORIG_HEAD`), or is one of the irregular root refs that `gitglossary`
lists.

#### Ref commit

@term ref-commit=v1
@cites {
    gitdoc/gitrepository-layout,
    gitdoc/gitglossary,
    gitdoc/git-worktree,
    gitdoc/git-pack-refs,
    gitdoc/reftable,
    #{git-directory=v1, working-tree=v1, commit=v1, ref-name=v1},
}

A ref of a git repository, or of a `working-tree` of that git
repository, has a `ref-name`. Per `gitglossary`, a ref either points to
a git object or is a symbolic ref.

The refs that a directory holds follow the ref storage format of the
repository (`git-directory`):

- For `files`: the directory's loose refs (including refs in the root of
  the ref hierarchy per `gitrepository-layout`, `git-pack-refs`, and
  `git-worktree`) plus, for the git directory, each ref in its
  `packed-refs` file whose ref name no loose ref of the git directory
  has (`git-pack-refs`).
- For `reftable` (versions 1 and 2): the refs in the stack of tables of
  that directory (`reftable`).

The **own refs** of a working tree are the refs that `git-worktree` (in
its section on refs) designates as not shared between working trees. A
working tree holds its own refs from the directory of that working tree
and every other ref from the git directory. A git repository holds every
ref from the git directory.

A ref **exists** when the git repository, or the working tree, holds a
ref with that ref name, regardless of what that ref points to or names.

The **commit of a ref** is the git object to which that ref resolves
(following any chain of symbolic refs within the same git repository or
working tree) when that git object is a `commit`. A symbolic ref that
names a ref that does not exist, or whose chain of symbolic refs repeats
a ref, resolves to no git object. A ref that does not exist, resolves to
no git object, or resolves to a git object that is not a commit object
has no commit. The commit of a pseudoref (`gitglossary`) is not
specified.

#### Head commit

@term head-commit=v1
@cites {gitdoc/gitglossary, #{working-tree=v1, ref-commit=v1}}

The **HEAD** of a `working-tree` is the ref `HEAD` of that working tree,
stored in the directory of that working tree (`gitglossary`). A working
tree's HEAD names another ref, or, when detached, points directly to a
git object.

The **head commit** of a working tree is the commit (`ref-commit`) of
its HEAD. A working tree whose HEAD has no commit has no head commit.

#### Reflog commit

@term reflog-commit=v1
@cites {
    gitdoc/gitrepository-layout,
    gitdoc/gitglossary,
    gitdoc/git-reflog,
    gitdoc/git-update-ref,
    gitdoc/reftable,
    #{
        git-directory=v1, working-tree=v1, commit=v1, ref-name=v1,
        ref-commit=v1,
    },
}

The **reflog** of a ref with `ref-name` `r` is git's local log of
updates to that ref (`gitglossary`, `git-reflog`). The entries of the
reflog of `r` that a directory holds follow the ref storage format of
the git repository (`git-directory`):

- For `files`: the entries of the file `logs/` followed by `r` in that
  directory (`gitrepository-layout`, `git-update-ref`).
- For `reftable` (versions 1 and 2): the log entries for `r` in the
  stack of tables of that directory (`reftable`).

For a `working-tree`, the reflog of an own ref (`ref-commit`) comes from
the directory of that working tree, and the reflog of every other ref
comes from the git directory. For a git repository, the reflog of every
ref comes from the git directory. The reflog of `r` is the reflog
recorded under `r` itself, without following symbolic refs. When the
directory holds no reflog for `r`, the reflog of `r` has no entries.

Each entry of the reflog of `r` records an old object name and a new
object name for one update of `r` (`git-update-ref`, `reftable`). A
**reflog commit** of `r` is a `commit` whose object name is the old
object name or the new object name of at least one entry of the reflog
of `r`. An all-zero object name or an object name that names a git
object that is not a commit object contributes no reflog commit. The
**reflog commits** of `r` are the set of all reflog commits of `r`
(empty when the reflog of `r` has no entries).

#### Mapped ref

@term mapped-ref=v1
@cites {
    gitdoc/gitglossary,
    gitdoc/git-config,
    gitdoc/git-fetch,
    text#text=v1,
    #{git-configuration=v1, ref-name=v1},
}

For a remote name `r` (a `text`) and a `ref-name` `m` in a git
repository, the **fetch refspecs** of `r` are the values of the setting
`remote.<name>.fetch`, with `r` for `<name>`, in the `git-configuration`
of the git repository, in order (`gitglossary`, `git-config`,
`git-fetch`). When any value of that setting is not a fetch refspec, the
mapped ref of `m` for `r` is not specified.

Otherwise, using the fetch refspecs of `r` as a mapping (`git-fetch`),
the **mapped ref** of `m` for `r` follows the first matching case:

1. If any negative fetch refspec among the fetch refspecs of `r` matches
   `m`, then `m` has no mapped ref for `r`.
2. If no positive fetch refspec among the fetch refspecs of `r` both
   matches `m` and has a non-empty destination, then `m` has no mapped
   ref for `r`.
3. If every positive fetch refspec among them that matches `m` and has a
   non-empty destination maps `m` to the same text: when that text is a
   `ref-name`, that ref name is the mapped ref of `m` for `r`;
   otherwise, `m` has no mapped ref for `r`.
4. Otherwise (when matching positive fetch refspecs with non-empty
   destinations map `m` to different texts), the mapped ref of `m` for
   `r` is not specified.

#### Branch name

@term branch-name=v1
@cites {
    gitdoc/git-check-ref-format,
    text#{character=v1, text=v1},
}

A **branch name** is a `text` `b` that meets all three of these
conditions:

1. The text `refs/heads/` followed by `b` meets the rules of
   `git-check-ref-format` for ref names.
2. `b` is not `HEAD`, and `b` does not start with the `character` `-`.
3. `b` does not start with `refs/`.

@example Under
[git-check-ref-format](sinter:gitdoc/git-check-ref-format) and
[text](sinter:text#text=v1), `main`, `release/2.0`, `@`, `refs`,
`HEADx`, `x-`, and `a/-b` are branch names. `HEAD`, `-x`, `refs/x`,
`refs/heads/main`, `a..b`, `.hidden`, `topic.lock`, and `a b` are not
branch names.

#### Default-branch commit

@term default-branch-commit=v1
@cites {
    gitdoc/gitglossary,
    gitdoc/git-config,
    gitdoc/git-fetch,
    ontology#{default-branch=v1, parameter=v1},
    #{
        git-configuration=v1, ref-commit=v1, mapped-ref=v1,
        branch-name=v1, default-branch-name=v1,
    },
}

Under a valid binding `b` (a `branch-name`) of the `parameter`
`default-branch-name`, the `default-branch` of a git repository is the
branch whose ref name is `refs/heads/` followed by `b`. Under that
binding, the three candidate refs of the default branch stand in this
order:

1. **The upstream of `b`:** the upstream branch ref name defined by
   `gitglossary`, `git-config` (entries `branch.<name>.remote` and
   `branch.<name>.merge`), and `git-fetch` from those two settings, with
   `b` for `<name>`, in the `git-configuration` of the git repository.
   When `branch.<name>.remote` is not `.`, this ref name is the
   `mapped-ref` of the remote ref name named by `branch.<name>.merge`
   for the remote named by `branch.<name>.remote`. When the git
   configuration specifies no such ref name, `b` has no upstream. When
   `branch.<name>.merge` (with `b` for `<name>`) has more than one value
   in the git configuration of the git repository, the upstream of `b`
   and the commit of the default branch are not specified.
2. The ref whose name is `refs/heads/` followed by `b`.
3. The ref whose name is `refs/remotes/origin/` followed by `b`.

Under that binding, the **commit of the default branch** is the commit
(`ref-commit`) of the first of these three refs that exists in the git
repository. When none of them exists, or when the first of them that
exists has no commit, the default branch has no commit.

@example Under the binding `main` of
[default-branch-name](sinter:#default-branch-name=v1), suppose the
[git configuration](sinter:#git-configuration=v1) sets
`branch.main.remote` to `origin`, `branch.main.merge` to
`refs/heads/main`, and `remote.origin.fetch` to
`+refs/heads/*:refs/remotes/origin/*`. By
[mapped-ref](sinter:#mapped-ref=v1), the upstream of `main` is
`refs/remotes/origin/main`. If `refs/remotes/origin/main` exists and
resolves to a commit under [ref-commit](sinter:#ref-commit=v1), that
commit is the commit of the default branch; if
`refs/remotes/origin/main` exists but has no commit (for example, as a
dangling symbolic ref), the default branch has no commit even if
`refs/heads/main` exists.

### Validating branch names

@req validate-branch-names=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #branch-name=v1,
}

When validating a `text` as a branch name, a conforming program must
return `"valid"` when the text is a `branch-name`, and must return
`"invalid"` otherwise.

### Returning ref commits

@req give-ref-commits=v1
@cites {
    conformance#conforming-program=v1,
    #{
        commit=v1, ref-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When resolving a ref of a git repository in an undisturbed
`repository-read` (`undisturbed-read`), a conforming program must return
the `commit` (`ref-commit`) of that ref when that ref has a commit, and
must return no commit when that ref has no commit.

### Returning head commits

@req give-head-commits=v1
@cites {
    conformance#conforming-program=v1,
    #{
        working-tree=v1, commit=v1, head-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When resolving the `HEAD` of a `working-tree` in an undisturbed
`repository-read` (`undisturbed-read`), a conforming program must return
the `head-commit` of that working tree when that working tree has a head
commit, and must return no commit when that working tree has no head
commit.

### Returning default-branch commits

@req give-default-branch-commits=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{default-branch=v1, parameter=v1},
    #{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

When resolving the commit of the `default-branch` of a git repository
under a valid binding of the `parameter` `default-branch-name` in an
undisturbed `repository-read` (`undisturbed-read`), a conforming program
must return the `commit` (`default-branch-commit`) of the default branch
when the default branch has a commit, and must return no commit when the
default branch has no commit.

### Returning reflog commits

@req give-reflog-commits=v1
@cites {
    conformance#conforming-program=v1,
    #{
        working-tree=v1, ref-name=v1, reflog-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

When reading the reflog commits of a ref with `ref-name` `r` of a git
repository or of a `working-tree` in an undisturbed `repository-read`
(`undisturbed-read`), a conforming program must return the exact set of
reflog commits (`reflog-commit`) of `r`.

### Returning mapped refs

@req give-mapped-refs=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #{
        ref-name=v1, mapped-ref=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When mapping a `ref-name` `m` for a remote name `r` (a `text`) in a git
repository in an undisturbed `repository-read` (`undisturbed-read`), a
conforming program must return the `mapped-ref` of `m` for `r` when `m`
has a mapped ref for `r`, and must return no mapped ref when `m` has no
mapped ref for `r`.

### Test vectors

Test vectors for `refs` live in
[changes.test-vectors.jsonl](changes.test-vectors.jsonl). No group uses
`needs`.

#### Branch name vectors

@schema branch-name-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    text#text=v1,
    #{validate-branch-names=v1, branch-name=v1},
}

`branch-name-vector` is a `group-schema` for group `branch-names` and
tests `validate-branch-names`. Each line is a `vector-line` whose
meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input` | string | `text` to validate as a branch name |
| `result` | string | `"valid"` when `input` is a `branch-name`, `"invalid"` otherwise |

@example Sample lines testing
[validate-branch-names](sinter:#validate-branch-names=v1) on invalid and
valid [branch-name](sinter:#branch-name=v1) inputs:

```json
{"form":"#branch-name-vector=v1","group":"branch-names","input":"HEAD","note":"a branch name is not `HEAD`","result":"invalid"}
{"form":"#branch-name-vector=v1","group":"branch-names","input":"refs","note":"the text does not start with `refs/`","result":"valid"}
```

#### Ref commit vectors

@schema ref-commit-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    #{
        give-ref-commits=v1, commit=v1, ref-name=v1, ref-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

`ref-commit-vector` is a `group-schema` for group `ref-commits` and
tests `give-ref-commits`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector represents an undisturbed
`repository-read` (`undisturbed-read`) of a git repository holding every
`commit` (by short commit name) and every non-commit git object (by
short object name) named in `input`, and no other git object.

| field | type | meaning |
|---|---|---|
| `input.ref` | string | `ref-name` to resolve |
| `input.refs` | object | map from each existing `ref-name` in the repository to a single-member target object: `{"commit": "<name>"}` (a `commit`, by short commit name), `{"ref": "<ref-name>"}` (a symbolic ref), or `{"other": "<name>"}` (a non-commit git object, by short object name); no other ref exists |
| `values.commit` | string (optional) | short commit name of the resolved `commit` (`ref-commit`); absent (`values` is `{}`) when `input.ref` has no commit |

@example Sample lines testing
[give-ref-commits](sinter:#give-ref-commits=v1) on symbolic and dangling
refs under [ref-commit](sinter:#ref-commit=v1):

```json
{"form":"#ref-commit-vector=v1","group":"ref-commits","input":{"ref":"refs/heads/alias","refs":{"refs/heads/alias":{"ref":"refs/heads/main"},"refs/heads/alias2":{"ref":"refs/heads/alias"},"refs/heads/dangling":{"ref":"refs/heads/gone"},"refs/heads/main":{"commit":"c"},"refs/tags/v1":{"other":"t"}}},"note":"a symbolic ref","values":{"commit":"c"}}
{"form":"#ref-commit-vector=v1","group":"ref-commits","input":{"ref":"refs/heads/dangling","refs":{"refs/heads/alias":{"ref":"refs/heads/main"},"refs/heads/alias2":{"ref":"refs/heads/alias"},"refs/heads/dangling":{"ref":"refs/heads/gone"},"refs/heads/main":{"commit":"c"},"refs/tags/v1":{"other":"t"}}},"note":"a symbolic ref that names a ref that does not exist","values":{}}
```

#### Head commit vectors

@schema head-commit-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    #{
        give-head-commits=v1, working-tree=v1, commit=v1, ref-name=v1,
        head-commit=v1, repository-read=v1, undisturbed-read=v1,
    },
}

`head-commit-vector` is a `group-schema` for group `head-commits` and
tests `give-head-commits`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector represents an undisturbed
`repository-read` (`undisturbed-read`) of a `working-tree` in a git
repository holding every `commit` named by short commit name in `input`,
and no other commit.

| field | type | meaning |
|---|---|---|
| `input.head` | object | working tree's HEAD, with one member: `{"ref": "<ref-name>"}` (symbolic HEAD) or `{"commit": "<name>"}` (detached HEAD pointing to a `commit` by short commit name) |
| `input.refs` | object | map from each existing `ref-name` in the repository to the short commit name of the `commit` to which that ref points (`{}` when none) |
| `values.commit` | string (optional) | short commit name of the `head-commit`; absent (`values` is `{}`) when the working tree has no head commit |

@example Sample lines testing
[give-head-commits](sinter:#give-head-commits=v1) under
[head-commit](sinter:#head-commit=v1) for an unborn branch and a
non-branch HEAD target:

```json
{"form":"#head-commit-vector=v1","group":"head-commits","input":{"head":{"ref":"refs/heads/main"},"refs":{}},"note":"a new repository: the branch that HEAD names does not exist","values":{}}
{"form":"#head-commit-vector=v1","group":"head-commits","input":{"head":{"ref":"refs/remotes/origin/main"},"refs":{"refs/remotes/origin/main":"e"}},"note":"HEAD can name a ref that is not a branch","values":{"commit":"e"}}
```

#### Default-branch commit vectors

@schema default-branch-commit-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    #{
        give-default-branch-commits=v1, default-branch-name=v1,
        branch-name=v1, default-branch-commit=v1, commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

`default-branch-commit-vector` is a `group-schema` for group
`default-branch-commits` and tests `give-default-branch-commits`. Each
line is a `vector-line` whose meaning follows `vector-meaning`. Each
vector represents an undisturbed `repository-read` (`undisturbed-read`)
of a git repository holding every `commit` named by short commit name in
`input`, and no other commit.

| field | type | meaning |
|---|---|---|
| `input.binding` | string | valid binding `b` of `default-branch-name` (a `branch-name`) |
| `input.upstream` | string or `{}` (optional) | present when, and only when, the upstream ref of `b` exists: short commit name of its `commit`, or `{}` when that ref has no commit |
| `input.local` | string or `{}` (optional) | present when, and only when, `refs/heads/` followed by `b` exists: short commit name of its `commit`, or `{}` when that ref has no commit |
| `input.remote` | string or `{}` (optional) | present when, and only when, `refs/remotes/origin/` followed by `b` exists: short commit name of its `commit`, or `{}` when that ref has no commit |
| `values.commit` | string (optional) | short commit name of the `default-branch-commit`; absent (`values` is `{}`) when the default branch has no commit |

@example Sample lines testing
[give-default-branch-commits](sinter:#give-default-branch-commits=v1)
under [default-branch-commit](sinter:#default-branch-commit=v1),
including an existing upstream with no commit:

```json
{"form":"#default-branch-commit-vector=v1","group":"default-branch-commits","input":{"binding":"main","local":"l","remote":"r","upstream":"u"},"note":"the upstream comes first","values":{"commit":"u"}}
{"form":"#default-branch-commit-vector=v1","group":"default-branch-commits","input":{"binding":"main","local":"l","upstream":{}},"note":"the upstream exists and has no commit, so the local branch does not count","values":{}}
```

#### Upstream vectors

@schema upstream-vector=v1
@cites {
    gitdoc/git-config,
    gitdoc/git-fetch,
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    text#text=v1,
    #{
        give-default-branch-commits=v1, default-branch-name=v1,
        branch-name=v1, git-configuration=v1, commit=v1, ref-name=v1,
        default-branch-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

`upstream-vector` is a `group-schema` for group `upstreams` and tests
`give-default-branch-commits`. Each line is a `vector-line` whose
meaning follows `vector-meaning`. Each vector represents an undisturbed
`repository-read` (`undisturbed-read`) of a git repository holding every
`commit` named by short commit name in `input`, and no other commit.

| field | type | meaning |
|---|---|---|
| `input.binding` | string | valid binding `b` of `default-branch-name` (a `branch-name`) |
| `input.settings` | object | `git-configuration` settings of the repository: each key is a setting name whose section and variable names (`git-config`) contain no uppercase ASCII letter `A` to `Z` (no two keys name the same setting), mapped to an array of its `text` values in order; every `remote.<name>.fetch` value is a fetch refspec (`git-fetch`), and `branch.<name>.merge` for `b` has at most one value |
| `input.refs` | object | map from each existing `ref-name` in the repository to the short commit name of the `commit` to which that ref points (`{}` when none) |
| `values.commit` | string (optional) | short commit name of the `default-branch-commit`; absent (`values` is `{}`) when the default branch has no commit |

@example Sample lines testing
[give-default-branch-commits](sinter:#give-default-branch-commits=v1)
with upstream derivation under
[default-branch-commit](sinter:#default-branch-commit=v1) and
[mapped-ref](sinter:#mapped-ref=v1):

```json
{"form":"#upstream-vector=v1","group":"upstreams","input":{"binding":"main","refs":{"refs/heads/main":"l"},"settings":{"branch.main.merge":["refs/heads/main"],"branch.main.remote":["up"],"remote.up.fetch":["refs/heads/*:refs/remotes/up/*"],"remote.up.url":["/nowhere"]}},"note":"an upstream that does not exist is not the first ref that exists","values":{"commit":"l"}}
{"form":"#upstream-vector=v1","group":"upstreams","input":{"binding":"main","refs":{"refs/heads/main":"l","refs/remotes/up/main":"u"},"settings":{"branch.main.merge":["refs/heads/main"],"branch.main.remote":["up"],"remote.up.fetch":["refs/heads/*:refs/remotes/up/*"],"remote.up.url":["/nowhere"]}},"note":"an existing upstream comes before the local branch","values":{"commit":"u"}}
```

#### Reflog commit vectors

@schema reflog-commit-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    text#code-point-order=v1,
    #{
        give-reflog-commits=v1, git-directory=v1, commit=v1,
        ref-name=v1, reflog-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

`reflog-commit-vector` is a `group-schema` for group `reflog-commits`
and tests `give-reflog-commits`. Each line is a `vector-line` whose
meaning follows `vector-meaning`. Each vector represents an undisturbed
`repository-read` (`undisturbed-read`), in either the `files` or the
`reftable` ref storage format (`git-directory`), of a git repository
holding every `commit` (by short commit name) and every non-commit git
object (by short object name) named in `input`, and no other git object.

| field | type | meaning |
|---|---|---|
| `input.ref` | string | `ref-name` `r` whose reflog commits are read |
| `input.reflogs` | object | map from each `ref-name` that has a reflog in the repository to its array of entries from oldest to newest (`[]` when empty); no other ref has a reflog |
| `input.reflogs.<ref>[].old`, `input.reflogs.<ref>[].new` | object | old and new object names of an entry, each with one member: `{"commit": "<name>"}` (a `commit`, by short commit name), `{"other": "<name>"}` (a non-commit git object, by short object name), or `{"zero": true}` (the all-zero object name) |
| `values.commits` | array of strings | short commit names of the `reflog-commit`s of `r`, each once, in `code-point-order` (`[]` when none) |

@example Sample lines testing
[give-reflog-commits](sinter:#give-reflog-commits=v1) under
[reflog-commit](sinter:#reflog-commit=v1) for duplicate rollback commits
and non-commit entries:

```json
{"form":"#reflog-commit-vector=v1","group":"reflog-commits","input":{"ref":"refs/remotes/origin/log","reflogs":{"refs/remotes/origin/log":[{"new":{"commit":"a"},"old":{"zero":true}},{"new":{"commit":"b"},"old":{"commit":"a"}},{"new":{"commit":"a"},"old":{"commit":"b"}}]}},"note":"a rollback repeats `a`, and the reflog commits hold each commit once","values":{"commits":["a","b"]}}
{"form":"#reflog-commit-vector=v1","group":"reflog-commits","input":{"ref":"refs/remotes/origin/log","reflogs":{"refs/remotes/origin/log":[{"new":{"commit":"a"},"old":{"zero":true}},{"new":{"other":"t"},"old":{"commit":"a"}},{"new":{"commit":"b"},"old":{"other":"t"}}]}},"note":"a non-commit git object gives no reflog commit","values":{"commits":["a","b"]}}
```

#### Mapped ref vectors

@schema mapped-ref-vector=v1
@cites {
    gitdoc/git-config,
    gitdoc/git-fetch,
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    text#text=v1,
    #{
        give-mapped-refs=v1, git-configuration=v1, ref-name=v1,
        mapped-ref=v1, repository-read=v1, undisturbed-read=v1,
    },
}

`mapped-ref-vector` is a `group-schema` for group `mapped-refs` and
tests `give-mapped-refs`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector represents an undisturbed
`repository-read` (`undisturbed-read`) of a git repository.

| field | type | meaning |
|---|---|---|
| `input.remote` | string | remote name `r` (`text`) |
| `input.ref` | string | `ref-name` `m` to map |
| `input.settings` | object | `git-configuration` settings of the repository: each key is a setting name whose section and variable names (`git-config`) contain no uppercase ASCII letter `A` to `Z` (no two keys name the same setting), mapped to an array of its `text` values in order; every `remote.<name>.fetch` value is a fetch refspec (`git-fetch`), and every positive fetch refspec for `r` that matches `m` with a non-empty destination maps `m` to the same text |
| `values.ref` | string (optional) | `mapped-ref` of `m` for `r`; absent (`values` is `{}`) when `m` has no mapped ref for `r` |

@example Sample lines testing
[give-mapped-refs](sinter:#give-mapped-refs=v1) under
[mapped-ref](sinter:#mapped-ref=v1) for wildcard matching and negative
refspec exclusion:

```json
{"form":"#mapped-ref-vector=v1","group":"mapped-refs","input":{"ref":"refs/heads/log","remote":"origin","settings":{"remote.origin.fetch":["+refs/heads/*:refs/remotes/origin/*"]}},"note":"standard wildcard fetch refspec","values":{"ref":"refs/remotes/origin/log"}}
{"form":"#mapped-ref-vector=v1","group":"mapped-refs","input":{"ref":"refs/heads/log","remote":"origin","settings":{"remote.origin.fetch":["+refs/heads/*:refs/remotes/origin/*","^refs/heads/log"]}},"note":"a negative fetch refspec after a positive one excludes `ref`","values":{}}
```

## Trees

@spec trees=v1

A commit and a working tree each have a tree of files with valid paths
and byte contents. The tree of a commit comes from the entries of its
git tree object. The tree of a working tree comes from the regular files
under its root directory, git's index, and git's ignore patterns.

### Definitions

#### Commit file

@term commit-file=v1
@cites {
    gitdoc/gitglossary,
    gitdoc/gitdatamodel,
    ontology#tree=v1,
    files#path=v1,
    text#{byte-sequence=v1, utf-8-encoding=v1},
    #commit=v1,
}

A git tree object lists entries, as `gitglossary` and `gitdatamodel`
define git tree objects. Each entry has a **name** (a `byte-sequence`),
a **mode**, and a git object. Each entry belongs to one of four kinds
according to the file type that `gitdatamodel` assigns to its mode:

- a **tree entry**, for the type directory (mode `40000`, written
  `040000` in `gitdatamodel`): names a git tree object;
- a **regular-file entry**, for the types regular file and executable
  file (modes `100644` and `100755`), and for mode `100664`: names a
  blob;
- a **symbolic-link entry**, for the type symbolic link (mode `120000`);
- a **submodule entry**, for the type gitlink (mode `160000`).

The **entries** of a git tree object `T`, each with its **byte path** (a
`byte-sequence`), are:

- each entry that `T` lists, with its name as its byte path; and
- for each tree entry `D` among them, each entry of the git tree object
  that `D` names, with the byte path of `D`, then the byte `0x2F`, then
  its byte path in that git tree object.

The files of the `tree` of a `commit`, and their contents, are the same
whether or not the git repository holds the git objects from which they
come. The **files of the tree of the commit** are exactly these: for
each regular-file entry `E` of the git tree object of the commit whose
byte path is the `utf-8-encoding` of a valid `path` `p`, the file whose
valid path is `p` and whose content is the content of the blob that `E`
names. When two entries of the git tree object of a commit share one
byte path, the files of the tree of that commit are not specified.

#### Ignored path

@term ignored-path=v1
@cites {
    gitdoc/git-config,
    gitdoc/gitignore,
    posix/2024,
    files#{file-kind=v1, path=v1},
    text#{character=v1, line=v1, utf-8-text=v1, valid-utf-8=v1},
    #{git-configuration=v1, git-directory=v1, working-tree=v1},
}

The **excludes file** of a `working-tree` is the file that
`core.excludesFile` names in the `git-configuration` of that working
tree, or, when that setting has no value there, the default file that
`git-config` defines for `core.excludesFile` in the environment in which
the program started.

A valid `path` is **ignored** in a `working-tree` when the patterns from
the sources that `gitignore` defines for paths of a working tree—other
than the command line—ignore that valid path under the rules of
`gitignore`, as for a file that git's index does not hold. Among those
sources, the file `info/exclude` of the `git-directory` and the excludes
file are the files that their POSIX.1-2024 pathnames name with symbolic
links (`file-kind`) on those pathnames followed.

For a source that is a regular file (`file-kind`), when its content is
`valid-utf-8` and its `utf-8-text` does not end with a carriage return
(U+000D) and holds no U+0000 (`character`), the patterns of that source
come from the `line`s of that text under the rules of `gitignore`. When
the content of a regular-file source does not meet those conditions, the
patterns of that source are not specified. When whether a valid path is
ignored in the working tree depends under `gitignore` on the patterns of
a regular-file source whose patterns are not specified, whether that
valid path is ignored in the working tree is not specified.

When `core.ignoreCase` in the `git-configuration` of the working tree is
true (under the boolean rules of `git-config`), a pattern also matches
every valid path that differs from a valid path matched by the pattern
only in the case of ASCII letters `A` through `Z`.

#### Working-tree file

@term working-tree-file=v1
@cites {
    gitdoc/gitformat-index,
    gitdoc/git-config,
    ontology#tree=v1,
    files#{
        directory=v1, directory-tree=v1, file-kind=v1, path=v1,
        path-resolution=v1,
    },
    text#{
        byte-sequence=v1, text=v1, utf-8-encoding=v1, valid-utf-8=v1,
    },
    #{
        commit=v1, commit-file=v1, git-configuration=v1,
        ignored-path=v1, working-tree=v1,
    },
}

For a `working-tree`, the **files of the tree of the working tree**
(`ontology#tree`) are exactly these: for each valid `path` `p` that
meets all three of these conditions and whose last path segment names a
regular file `F` (`file-kind`) in the `directory-tree` rooted at the
root directory of that working tree (`path-resolution`), the file whose
valid path is `p` and whose content is the content of `F`:

1. The first path segment of `p` is neither `.git` nor `.jj`.
2. No `directory` of the path of `p` (`path-resolution`), other than the
   root, holds a directory entry whose entry name is the
   `utf-8-encoding` of the `text` `.git`.
3. Git's index of the working tree holds an entry for the
   `utf-8-encoding` of `p`, or `p` is not ignored in the working tree
   (`ignored-path`).

Git's index holds an entry for a byte path `b` (`commit-file`) when
git's index has an entry whose path is `b`, or has a **sparse directory
entry** (`gitformat-index`) that summarizes `b`, whether or not the git
repository (`commit`) holds the git tree object that the sparse
directory entry names.

When `core.precomposeUnicode` in the `git-configuration` of the working
tree is true (under the boolean rules of `git-config`), and the entry
name of a regular file in the directory tree rooted at the root
directory of the working tree—or of a directory between the root
directory and that regular file—is `valid-utf-8` and holds a byte
(`byte-sequence`) of `0x80` or greater, whether that regular file
produces a file of the tree of the working tree, and under which valid
path, is not specified.

@example Suppose the root [directory](sinter:files#directory=v1) of a
[working tree](sinter:#working-tree=v1) holds `.git`, `.gitignore` with
the pattern `build/`, a modified tracked
[regular file](sinter:files#file-kind=v1) `a.md`, a
[symbolic link](sinter:files#file-kind=v1) `link` to `docs`, directory
`docs` holding `b.md`, directory `build` holding `out.md`, and submodule
directory `lib` holding `.git` and `c.md`. Git's index holds
`.gitignore`, `a.md`, `docs/b.md`, and `lib`. The files of the
[tree](sinter:ontology#tree=v1) of the working tree have the
[valid paths](sinter:files#path=v1) `.gitignore`, `a.md` (with its
current content on disk rather than the content that git's index
records), and `docs/b.md`. The `.git` entry at the root and every file
under `lib` (which holds a `.git` entry) are excluded, `link` is a
symbolic link rather than a regular file, and `build/out.md` is
[ignored](sinter:#ignored-path=v1) and not in git's index.

### Returning commit-tree files

@req give-commit-files=v1
@cites {
    conformance#conforming-program=v1,
    ontology#tree=v1,
    files#path=v1,
    #{
        commit=v1, commit-file=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When a conforming program returns the valid `path`s or files of the
`tree` of a `commit` (`commit-file`) in an undisturbed `repository-read`
(`undisturbed-read`), the program must return exactly the valid paths of
the files of that tree, and for each file whose content the program
returns, the program must return that file's exact content.

When a conforming program looks up a valid `path` `p` in the `tree` of a
`commit` (`commit-file`) in an undisturbed `repository-read`
(`undisturbed-read`), the program must return the file at `p` with its
exact content when that tree holds a file at `p`, and must return that
the tree holds no file at `p` when that tree holds no file at `p`.

### Returning working-tree files

@req give-working-tree-files=v1
@cites {
    conformance#conforming-program=v1,
    ontology#tree=v1,
    files#path=v1,
    #{
        working-tree=v1, working-tree-file=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When a conforming program returns the valid `path`s or files of the
`tree` of a `working-tree` (`working-tree-file`) in an undisturbed
`repository-read` (`undisturbed-read`), the program must return exactly
the valid paths of the files of that tree, and for each file whose
content the program returns, the program must return that file's exact
content.

When a conforming program looks up a valid `path` `p` in the `tree` of a
`working-tree` (`working-tree-file`) in an undisturbed `repository-read`
(`undisturbed-read`), the program must return the file at `p` with its
exact content when that tree holds a file at `p`, and must return that
the tree holds no file at `p` when that tree holds no file at `p`.

### Test vectors

Test vectors for `trees` live in
[changes.test-vectors.jsonl](changes.test-vectors.jsonl). Only group
`working-tree-files` uses `needs`.

#### Commit-tree file vectors

@schema commit-file-vector=v1
@cites {
    gitdoc/gitdatamodel,
    conformance#{conforming-program=v1, dependence=v1, input=v1},
    data-forms#{
        group-schema=v1, hex-text=v1, json-value=v1, vector-line=v1,
        vector-meaning=v1,
    },
    ontology#tree=v1,
    files#path=v1,
    text#{
        byte-sequence=v1, code-point-order=v1, text=v1,
        utf-8-encoding=v1,
    },
    #{
        commit=v1, commit-file=v1, give-commit-files=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

`commit-file-vector` is a `group-schema` for group `commit-files` and
tests `give-commit-files`. Each line is a `vector-line` whose meaning
follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.entries[]` | array of objects | entries listed by the commit's git tree object, in listed order, with no two entries sharing a byte path |
| `input.entries[].name` | string or `{"bytes": hex-text}` | entry name `byte-sequence`: a JSON string when it is the `utf-8-encoding` of a `text`, and `{"bytes": hex-text}` otherwise |
| `input.entries[].mode` | string | entry mode: `"40000"` (written `040000` in `gitdatamodel`) for a tree entry; `"100644"`, `"100664"`, or `"100755"` for a regular-file entry; `"120000"` for a symbolic-link entry; `"160000"` for a submodule entry |
| `input.entries[].entries` | array of objects (tree entries only) | nested entries of the named git tree object in the same form; present on every `"40000"` entry and absent on all other entries |
| `values.paths` | array of strings | valid `path`s of the files of the commit's `tree` (`commit-file`), each once, in `code-point-order` |

Each JSON object (`json-value`) holds only its defined members. The git
repository holds the input `commit` and no other commit, and lacks no
git object that the vector needs (`input`, `dependence`). Each vector
represents an undisturbed `repository-read` (`undisturbed-read`). Each
regular-file entry and symbolic-link entry names a blob, and each
submodule entry names a commit of another git repository; vectors omit
those blob contents and commits.

Under `give-commit-files`, a conforming program returning the commit
tree's valid paths or files returns exactly the paths in `values.paths`
(each with the content of its entry's blob when returning contents), and
a conforming program looking up a valid path `p` returns the file at `p`
with its blob content when `p` is in `values.paths` and returns that the
tree holds no file at `p` otherwise.

@example Sample lines testing
[give-commit-files](sinter:#give-commit-files=v1) and
[commit-file](sinter:#commit-file=v1) on mode `100664` and a non-UTF-8
entry name:

```json
{"form":"#commit-file-vector=v1","group":"commit-files","input":{"entries":[{"mode":"100664","name":"old.md"}]},"note":"an old mode of a regular file","values":{"paths":["old.md"]}}
{"form":"#commit-file-vector=v1","group":"commit-files","input":{"entries":[{"mode":"100644","name":{"bytes":"636166e92e6d64"}},{"mode":"100644","name":"ok.md"}]},"note":"a name that is not valid UTF-8","values":{"paths":["ok.md"]}}
```

#### Working-tree file vectors

@schema working-tree-file-vector=v1
@cites {
    gitdoc/git-config,
    conformance#conforming-program=v1,
    data-forms#{
        group-schema=v1, json-value=v1, vector-line=v1,
        vector-meaning=v1,
    },
    ontology#tree=v1,
    files#{
        directory=v1, directory-tree=v1, directory-tree-object=v1,
        file-kind=v1, path=v1,
    },
    text#{
        byte-sequence=v1, code-point-order=v1, utf-8-encoding=v1,
        valid-utf-8=v1,
    },
    #{
        commit=v1, git-configuration=v1, git-directory=v1,
        give-working-tree-files=v1, ignored-path=v1, repository-read=v1,
        undisturbed-read=v1, working-tree=v1, working-tree-file=v1,
    },
}

`working-tree-file-vector` is a `group-schema` for group
`working-tree-files` and tests `give-working-tree-files`. Each line is a
`vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.directory-tree` | `directory-tree-object` | `directory-tree` rooted at the working tree's root directory; every `.git` `directory` holds `entries: []` and every `.git` regular file holds `content: []` (the vector check supplies git-repository internals) |
| `input.tracked` | array of strings | valid `path`s `p` for which git's index holds an entry for the `utf-8-encoding` of `p`, each once, in `code-point-order` |
| `input.ignored` | array of strings | valid `path`s of regular files (`file-kind`) in `input.directory-tree` that are ignored in the working tree (`ignored-path`), each once, in `code-point-order`; can overlap `input.tracked` |
| `values.paths` | array of strings | valid `path`s of the files of the working tree's `tree` (`working-tree-file`), each once, in `code-point-order` |
| `needs` | array of strings (optional) | need names from the needs table of this group |

Each JSON object (`json-value`) holds only its defined members. The git
repository holds no `commit`. Each vector represents an undisturbed
`repository-read` (`undisturbed-read`) of the `working-tree` while a
file system stores the directory tree of `input.directory-tree`
(`directory-tree-object`) for the program's process, except that the
vector check supplies the omitted files and contents of `.git` entries
as needed by the git repository and establishes the index and ignore
state stated by `input.tracked` and `input.ignored`. When the root
directory of `input.directory-tree` holds no `.git` entry, the
`git-directory` sits outside that directory tree.

Under `give-working-tree-files`, a conforming program returning the
working tree's valid paths or files returns exactly the paths in
`values.paths` (each with the content of its regular file when returning
contents), and a conforming program looking up a valid path `p` returns
the file at `p` with its regular file's content when `p` is in
`values.paths` and returns that the tree holds no file at `p` otherwise.

Only these two need names are valid in `needs` for group
`working-tree-files`:

| need | environment condition | when a vector carries this need |
|---|---|---|
| `names-kept` | The file system keeps every entry name of `input.directory-tree` byte for byte without modification (such as Unicode normalization), and `core.precomposeUnicode` in the working tree's `git-configuration` is not true (`git-config`). | An entry name in `input.directory-tree` is `valid-utf-8` and holds a byte (`byte-sequence`) `>= 0x80`. |
| `non-utf-8-names` | The file system keeps every non-UTF-8 entry name of `input.directory-tree` byte for byte. | An entry name in `input.directory-tree` is not `valid-utf-8`. |

@example Sample lines testing
[give-working-tree-files](sinter:#give-working-tree-files=v1),
[working-tree-file](sinter:#working-tree-file=v1), and
[directory-tree-object](sinter:files#directory-tree-object=v1) on a
colocated jj repository and a non-UTF-8 entry name:

```json
{"form":"#working-tree-file-vector=v1","group":"working-tree-files","input":{"directory-tree":{"entries":[{"file":{"entries":[{"file":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"73746f7265"}],"type":"directory"},"name":"7265706f"}],"type":"directory"},"name":"2e6a6a"},{"file":{"content":[],"type":"regular file"},"name":"612e6d64"}],"type":"directory"},"ignored":[],"tracked":["a.md"]},"note":"a colocated jj repository","values":{"paths":["a.md"]}}
{"form":"#working-tree-file-vector=v1","group":"working-tree-files","input":{"directory-tree":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"636166e92e6d64"},{"file":{"content":[],"type":"regular file"},"name":"6f6b2e6d64"}],"type":"directory"},"ignored":[],"tracked":["ok.md"]},"needs":["non-utf-8-names"],"note":"a name that is not valid UTF-8","values":{"paths":["ok.md"]}}
```

#### Ignore-file vectors

@schema ignore-file-vector=v1
@cites {
    gitdoc/git-config,
    conformance#conforming-program=v1,
    data-forms#{
        group-schema=v1, json-value=v1, vector-line=v1,
        vector-meaning=v1,
    },
    ontology#tree=v1,
    files#{directory=v1, file-kind=v1, path=v1},
    text#{
        character=v1, code-point-order=v1, text=v1, utf-8-encoding=v1,
    },
    #{
        commit=v1, git-configuration=v1, git-directory=v1,
        give-working-tree-files=v1, ignored-path=v1, repository-read=v1,
        undisturbed-read=v1, working-tree=v1, working-tree-file=v1,
    },
}

`ignore-file-vector` is a `group-schema` for group `ignore-files` and
tests `give-working-tree-files`. Each line is a `vector-line` whose
meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.gitignore` | string | `text` that does not end with U+000D and holds no U+0000 (`character`); its `utf-8-encoding` is the content of the root directory's regular file `.gitignore` |
| `input.names` | array of strings | distinct ASCII-only (`< 128`) path segments (`path`) naming empty regular files (`file-kind`) in the root `directory`, in `code-point-order`; none equals or differs only in ASCII letter case (`A`–`Z`) from `.git`, `.gitignore`, or another element |
| `values.paths` | array of strings | valid `path`s of the files of the working tree's `tree` (`working-tree-file`), each once, in `code-point-order` |

Each JSON object (`json-value`) holds only its defined members. The git
repository holds no `commit`. Each vector represents an undisturbed
`repository-read` (`undisturbed-read`) of a `working-tree` whose root
`directory` holds the directory entry `.git` of its `git-directory`, the
regular file `.gitignore` with the `utf-8-encoding` of `input.gitignore`
as its content, an empty regular file for each element of `input.names`,
and no other directory entry. Git's index holds no entry,
`core.ignoreCase` in the working tree's `git-configuration` is not true
(`git-config`), and no other ignore-pattern source (`ignored-path`)
holds any pattern.

Under `give-working-tree-files`, a conforming program returning the
working tree's valid paths or files returns exactly the paths in
`values.paths` (each with the content of its regular file when returning
contents), and a conforming program looking up a valid path `p` returns
the file at `p` with its regular file's content when `p` is in
`values.paths` and returns that the tree holds no file at `p` otherwise.

@example Sample lines testing
[give-working-tree-files](sinter:#give-working-tree-files=v1) and
[ignored-path](sinter:#ignored-path=v1) on CRLF endings and a leading
byte order mark in `.gitignore`:

```json
{"form":"#ignore-file-vector=v1","group":"ignore-files","input":{"gitignore":"b.md\r\n","names":["a.md","b.md"]},"note":"a carriage return right before a line feed is in no pattern","values":{"paths":[".gitignore","a.md"]}}
{"form":"#ignore-file-vector=v1","group":"ignore-files","input":{"gitignore":"﻿b.md\n","names":["a.md","b.md"]},"note":"a byte order mark is in no pattern","values":{"paths":[".gitignore","a.md"]}}
```

## Commit graphs and changes

@spec history=v1

Commits in a git repository form a directed graph through their parent
links. Commit ranges, parents-first orders, merge bases, first-parent
lines, and landing commits are sets and sequences of commits determined
by that graph. The commit change and change base of a commit compare
that commit with the commit of the default branch to isolate the commits
of one unit of work.

### Definitions

#### Ancestry

@term ancestry=v1
@cites #commit=v1

The **ancestry** of a `commit` `c` is the smallest set of commits that
holds `c` and holds every parent of every commit in that set.

#### Reach

@atom reach=v1
@cites #{commit=v1, ancestry=v1}

A `commit` `c` **reaches** each commit in the `ancestry` of `c`,
including `c` itself, and reaches no other commit. For two commits `c`
and `c'`, the **reach** outcome is `"reaches"` when `c` reaches `c'`,
and `"does not reach"` otherwise.

#### Commit range

@term commit-range=v1
@cites #{commit=v1, reach=v1}

For two commits `s` and `h` of a git repository, the **commit range**
from `s` to `h` is the set of commits that `h` reaches and `s` does not
reach. For a single commit `h` of a git repository, the **commit range**
from no commit to `h` is the set of commits that `h` reaches.

#### Parents-first order

@term parents-first-order=v1
@cites #{commit=v1, commit-range=v1}

Let `R` be the `commit-range` from a commit `s`, or from no commit, to a
commit `h`. Walking a commit `c` in `R` performs three steps in order:

1. Mark `c` as started.
2. For each parent of `c` in the parent order of `c`, if that parent is
   in `R` and is not yet marked as started, walk that parent.
3. Mark `c` as finished.

When `h` is in `R`, the walk of `R` walks `h`. Otherwise, `R` is empty
and the walk of `R` walks no commit. The **parents-first order** of `R`
is the sequence of commits in `R` in the order in which the walk of `R`
marks them as finished. Every commit in `R` appears after every parent
of that commit that is in `R`.

@example In this commit graph, each commit points left to its parents
([commit](sinter:#commit=v1)), and merge commit `f` has first parent `c`
and second parent `e`:

```text
a <- b <- c <------- f <- g
      \             /
       d <------- e
```

For the [commit range](sinter:#commit-range=v1) from `b` to `g`
(`{c, d, e, f, g}`), the walk starts at `g`, enters `f`, walks first
parent `c` before second parent `e`, and enters `d` from `e`, finishing
in the parents-first order `c`, `d`, `e`, `f`, `g`. The commit range
from `c` to `e` has parents-first order `d`, `e`.

#### Commit change

@term commit-change=v1
@cites {
    ontology#{default-branch=v1, parameter=v1},
    #{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        commit-range=v1,
    },
}

Under a valid binding of the `parameter` `default-branch-name`, when the
`default-branch` of a git repository has a `default-branch-commit` `d`,
the **commit change** of a `commit` `h` of that git repository is the
`commit-range` from `d` to `h`. The **commits** of that commit change
are the commits of that range, and the **last commit** of that commit
change is `h` even when the range is empty. When the default branch has
no commit under that binding, `h` has no commit change.

#### Merge base

@term merge-base=v1
@cites #{commit=v1, reach=v1}

A **common ancestor** of two commits `a` and `b` is a `commit` that both
`a` and `b` reach. A **merge base** of `a` and `b` is a common ancestor
of `a` and `b` that no other common ancestor of `a` and `b` reaches.

#### Change base

@term change-base=v1
@cites {
    ontology#{default-branch=v1, parameter=v1},
    #{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        commit-change=v1, merge-base=v1,
    },
}

Under a valid binding of the `parameter` `default-branch-name`, when the
`default-branch` of a git repository has a `default-branch-commit` `d`,
the **change base** of a `commit` `h` (the base of the `commit-change`
of `h`) is the unique `merge-base` of `h` and `d` when `h` and `d` have
exactly one merge base. When `h` and `d` have no merge base or more than
one merge base, or when the default branch has no commit under that
binding, `h` has no change base.

@example Consider crossing merges where [commits](sinter:#commit=v1) `b`
and `c` each have parent `a`, commit `m1` has parents `b` and `c`, and
commit `m2` has parents `c` and `b`. The common ancestors of `m1` and
`m2` are `a`, `b`, and `c`. Both `b` and `c` [reach](sinter:#reach=v1)
`a`, so the [merge bases](sinter:#merge-base=v1) of `m1` and `m2` are
`b` and `c`. While the
[default branch](sinter:#default-branch-commit=v1) points to `m2`, the
[commit change](sinter:#commit-change=v1) of `m1` holds `m1`, and `m1`
has no change base. By contrast, when the default branch points to `m1`,
the commit change of `b` is empty and the change base of `b` is `b`.

#### First-parent line

@term first-parent-line=v1
@cites #commit=v1

The **first-parent line** of a `commit` `c` is the finite sequence of
commits that starts with `c`, in which each subsequent commit is the
first parent of the immediately preceding commit, and whose last commit
has no parent.

#### Landing commit

@term landing-commit=v1
@cites #{commit=v1, reach=v1, first-parent-line=v1}

For a `commit` `d` and a commit `c` that `d` reaches, the **landing
commit** of `c` on the `first-parent-line` of `d` is the unique commit
`m` on that first-parent line that reaches `c` and either has no parent
or has a first parent that does not reach `c`. The commits of that
first-parent line that reach `c` form a prefix of the sequence, so `m`
is the last commit in that first-parent line that reaches `c`. A commit
that `d` does not reach has no landing commit on the first-parent line
of `d`.

@example In the graph where [commits](sinter:#commit=v1) `a <- b <- c`,
`b <- d <- e`, merge commit `f` has first parent `c` and second parent
`e`, and `g` has parent `f`, the
[first-parent line](sinter:#first-parent-line=v1) of `g` is `g`, `f`,
`c`, `b`, `a`. Commit `f` [reaches](sinter:#reach=v1) `d` and `e` while
its first parent `c` does not, so the landing commit of both `d` and `e`
on that first-parent line is `f`. Commit `c` lies on the first-parent
line and its first parent `b` does not reach `c`, so `c` is its own
landing commit.

### Deciding reach

@req decide-reach=v1
@cites {
    conformance#conforming-program=v1,
    #{commit=v1, reach=v1, repository-read=v1, undisturbed-read=v1},
}

When a conforming program decides in an undisturbed `repository-read`
(`undisturbed-read`) whether a `commit` `c` of a git repository reaches
a commit `c'` of that git repository, the program must return the
`reach` outcome for `c` and `c'`.

### Returning commit ranges

@req give-ranges=v1
@cites {
    conformance#conforming-program=v1,
    #{
        commit=v1, commit-range=v1, parents-first-order=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

When a conforming program returns the commits of the `commit-range` from
a `commit` `s`, or from no commit, to a commit `h` of a git repository
in an undisturbed `repository-read` (`undisturbed-read`), the program
must return the commits of that commit range with no missing or extra
commits. When the program returns those commits in
`parents-first-order`, the program must return them in the parents-first
order of that commit range.

### Returning commit changes

@req give-commit-changes=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{default-branch=v1, parameter=v1},
    #{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        commit-change=v1, repository-read=v1, undisturbed-read=v1,
    },
}

When a conforming program returns the `commit-change` of a `commit` `h`
of a git repository, or that `h` has no commit change, under a valid
binding of the `parameter` `default-branch-name` in an undisturbed
`repository-read` (`undisturbed-read`), the program must return the
commits of the commit change of `h` (with no missing or extra commits,
including the empty set when that commit change holds no commit) when
the `default-branch` has a `default-branch-commit` under that binding,
and must return that `h` has no commit change when the default branch
has no commit under that binding.

### Returning merge bases

@req give-merge-bases=v1
@cites {
    conformance#conforming-program=v1,
    #{
        commit=v1, merge-base=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When a conforming program returns the `merge-base`s of two `commit`s of
a git repository in an undisturbed `repository-read`
(`undisturbed-read`), the program must return the merge bases of those
two commits with no missing or extra commits.

### Returning change bases

@req give-change-bases=v1
@cites {
    conformance#conforming-program=v1,
    ontology#parameter=v1,
    #{
        commit=v1, default-branch-name=v1, change-base=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

When a conforming program returns the `change-base` of a `commit` `h` of
a git repository, or that `h` has no change base, under a valid binding
of the `parameter` `default-branch-name` in an undisturbed
`repository-read` (`undisturbed-read`), the program must return the
change base of `h` under that binding when `h` has a change base, and
must return that `h` has no change base when `h` has no change base.

### Returning first-parent lines

@req give-first-parent-lines=v1
@cites {
    conformance#conforming-program=v1,
    #{
        commit=v1, first-parent-line=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

When a conforming program returns the `first-parent-line` of a `commit`
of a git repository in an undisturbed `repository-read`
(`undisturbed-read`), the program must return the commits of that
first-parent line in order, with no missing or extra commits.

### Returning landing commits

@req give-landing-commits=v1
@cites {
    conformance#conforming-program=v1,
    #{
        commit=v1, first-parent-line=v1, landing-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

When a conforming program returns the `landing-commit` of a `commit` `c`
on the `first-parent-line` of a commit `d` of a git repository, or that
`c` has no landing commit on that first-parent line, in an undisturbed
`repository-read` (`undisturbed-read`), the program must return the
landing commit of `c` on that first-parent line when `c` has one, and
must return that `c` has no landing commit on that first-parent line
when `c` has no landing commit on that first-parent line.

### Test vectors

Test vectors for `history` live in
[changes.test-vectors.jsonl](changes.test-vectors.jsonl). No group uses
`needs`.

#### Reach vectors

@schema reach-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    #{
        decide-reach=v1, commit=v1, shallow-commit=v1, reach=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

`reach-vector` is a `group-schema` for group `reach` and tests
`decide-reach`. Each line is a `vector-line` whose meaning follows
`vector-meaning` and represents an undisturbed `repository-read`
(`undisturbed-read`).

| field | type | meaning |
|---|---|---|
| `input.commits` | object | commit graph mapping each short commit name to an array of its parents' short commit names in parent order (`[]` for a root commit or a `shallow-commit`); the git repository holds these commits and no others |
| `input.commit` | string | short commit name of `commit` `c` |
| `input.other` | string | short commit name of `commit` `c'` |
| `result` | string | the `reach` outcome for `c` and `c'` |

@example Sample lines testing [decide-reach](sinter:#decide-reach=v1)
with [reach](sinter:#reach=v1):

```json
{"form":"#reach-vector=v1","group":"reach","input":{"commit":"g","commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"other":"d"},"note":"through the second parent of `f`","result":"reaches"}
{"form":"#reach-vector=v1","group":"reach","input":{"commit":"c","commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"other":"d"},"result":"does not reach"}
```

#### Commit range vectors

@schema range-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    #{
        give-ranges=v1, commit=v1, shallow-commit=v1, commit-range=v1,
        parents-first-order=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

`range-vector` is a `group-schema` for group `ranges` and tests
`give-ranges`. Each line is a `vector-line` whose meaning follows
`vector-meaning` and represents an undisturbed `repository-read`
(`undisturbed-read`).

| field | type | meaning |
|---|---|---|
| `input.commits` | object | commit graph mapping each short commit name to an array of its parents' short commit names in parent order (`[]` for a root commit or a `shallow-commit`); the git repository holds these commits and no others |
| `input.from` | string (optional) | short commit name of `commit` `s`; when present, the range is from `s` to `h`; when absent, the range is from no commit to `h` |
| `input.to` | string | short commit name of `commit` `h` |
| `values.order` | array of strings | short commit names of the commits in the `commit-range` in `parents-first-order` (a program that returns the commits of the range returns these commits with no missing or extra commits; a program that returns them in parents-first order returns them in this exact order) |

@example Sample lines testing [give-ranges](sinter:#give-ranges=v1) with
[commit-range](sinter:#commit-range=v1) and
[parents-first-order](sinter:#parents-first-order=v1):

```json
{"form":"#range-vector=v1","group":"ranges","input":{"commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"from":"b","to":"g"},"note":"the walk from `g` takes the first parent `c` of `f` before its second parent `e`","values":{"order":["c","d","e","f","g"]}}
{"form":"#range-vector=v1","group":"ranges","input":{"commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"to":"e"},"note":"the range from no commit is the ancestry","values":{"order":["a","b","d","e"]}}
```

#### Commit change and merge base vectors

@schema change-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    ontology#parameter=v1,
    text#code-point-order=v1,
    #{
        give-commit-changes=v1, give-merge-bases=v1,
        give-change-bases=v1, commit=v1, shallow-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
        commit-change=v1, merge-base=v1, change-base=v1,
        repository-read=v1, undisturbed-read=v1,
    },
}

`change-vector` is a `group-schema` for group `changes` and tests
`give-commit-changes`, `give-merge-bases`, and `give-change-bases`. Each
line is a `vector-line` whose meaning follows `vector-meaning` and
represents an undisturbed `repository-read` (`undisturbed-read`).

| field | type | meaning |
|---|---|---|
| `input.commits` | object | commit graph mapping each short commit name to an array of its parents' short commit names in parent order (`[]` for a root commit or a `shallow-commit`); the git repository holds these commits and no others |
| `input.default` | string (optional) | short commit name of the `default-branch-commit` under a valid binding of the `parameter` `default-branch-name`; absent when no `default-branch-commit` exists under that binding |
| `input.last` | string | short commit name of `commit` `h` |
| `values.change` | array of strings (optional) | present when, and only when, `input.default` is present: short commit names of the commits in the `commit-change` of `h`, each once, sorted in `code-point-order` (`[]` when empty); absent when `h` has no commit change |
| `values.merge-bases` | array of strings (optional) | present when, and only when, `input.default` is present: short commit names of the `merge-base` commits of `h` and `input.default`, each once, sorted in `code-point-order` (`[]` when none); absent when `input.default` is absent |
| `values.base` | string (optional) | short commit name of the `change-base` of `h` when `h` has one; absent when `h` has no change base (`values` is `{}` when `input.default` is absent) |

@example Sample lines testing
[give-commit-changes](sinter:#give-commit-changes=v1),
[give-merge-bases](sinter:#give-merge-bases=v1), and
[give-change-bases](sinter:#give-change-bases=v1) with
[commit-change](sinter:#commit-change=v1),
[merge-base](sinter:#merge-base=v1), and
[change-base](sinter:#change-base=v1):

```json
{"form":"#change-vector=v1","group":"changes","input":{"commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"default":"g","last":"e"},"note":"the default branch reaches `e`: the change holds no commit, and its base is `e`","values":{"base":"e","change":[],"merge-bases":["e"]}}
{"form":"#change-vector=v1","group":"changes","input":{"commits":{"a":[],"b":["a"],"c":["a"],"m1":["b","c"],"m2":["c","b"]},"default":"m2","last":"m1"},"note":"merges that cross: two merge bases, so no base","values":{"change":["m1"],"merge-bases":["b","c"]}}
```

#### First-parent line and landing commit vectors

@schema landing-commit-vector=v1
@cites {
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    #{
        give-first-parent-lines=v1, give-landing-commits=v1, commit=v1,
        shallow-commit=v1, reach=v1, first-parent-line=v1,
        landing-commit=v1, repository-read=v1, undisturbed-read=v1,
    },
}

`landing-commit-vector` is a `group-schema` for group `landing-commits`
and tests `give-first-parent-lines` and `give-landing-commits`. Each
line is a `vector-line` whose meaning follows `vector-meaning` and
represents an undisturbed `repository-read` (`undisturbed-read`).

| field | type | meaning |
|---|---|---|
| `input.commits` | object | commit graph mapping each short commit name to an array of its parents' short commit names in parent order (`[]` for a root commit or a `shallow-commit`); the git repository holds these commits and no others |
| `input.line-of` | string | short commit name of `commit` `d` |
| `input.commit` | string | short commit name of `commit` `c` |
| `values.first-parent-line` | array of strings | short commit names of the commits in the `first-parent-line` of `d`, in order |
| `values.landing-commit` | string (optional) | short commit name of the `landing-commit` of `c` on the `first-parent-line` of `d` when `d` reaches `c`; absent when `c` has no landing commit on that first-parent line |

@example Sample lines testing
[give-first-parent-lines](sinter:#give-first-parent-lines=v1) and
[give-landing-commits](sinter:#give-landing-commits=v1) with
[first-parent-line](sinter:#first-parent-line=v1) and
[landing-commit](sinter:#landing-commit=v1):

```json
{"form":"#landing-commit-vector=v1","group":"landing-commits","input":{"commit":"d","commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"line-of":"g"},"note":"`d` landed on the first-parent line of `g` through the merge commit `f`","values":{"first-parent-line":["g","f","c","b","a"],"landing-commit":"f"}}
{"form":"#landing-commit-vector=v1","group":"landing-commits","input":{"commit":"c","commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"line-of":"e"},"note":"`e` does not reach `c`","values":{"first-parent-line":["e","d","b","a"]}}
```

## Hunks and change diffs

@spec diffs=v1

An old tree and a new tree can hold different contents at the same valid
path, or a file at that path in only one of the two trees. A line map
pairs equal lines of the two contents. The unpaired lines form hunks,
and each paired old line has a new line number. A change diff compares
the tree of a commit's change base with the tree of that commit across
every valid path.

### Definitions

#### Line text

@term line-text=v1
@cites {
    ontology#tree=v1,
    files#path=v1,
    text#{text=v1, line=v1, valid-utf-8=v1, utf-8-text=v1},
}

For a valid `path` `p` and a `tree` `A`, when `A` holds a file at `p`
whose content is `valid-utf-8`, the **line texts** of `p` in `A` are
the `text`s of the `line`s of that content's `utf-8-text`, in 1-based
line-number order: **line text `k`** of `p` in `A` is the text of the
line with 1-based line number `k`. Otherwise (`A` holds no file at `p`,
or the file's content is not `valid-utf-8`), `p` has no line texts in
`A` (a count of 0).

#### Line map

@term line-map=v1
@cites {
    ontology#tree=v1,
    files#path=v1,
    text#{text=v1, line=v1, utf-8-text=v1},
    #line-text=v1,
}

For a valid `path` `p`, an old `tree` `A`, and a new `tree` `B`, let
`m` be the count of `line-text`s of `p` in `A` and let `n` be the count
of `line-text`s of `p` in `B`. A **map** of `p` between `A` and `B` is
a set of integer pairs `(i, j)` that meets all three of these
conditions:

1. For each pair `(i, j)` in the set, `1 <= i <= m` and `1 <= j <= n`.
2. For each pair `(i, j)` in the set, line text `i` of `p` in `A` and
   line text `j` of `p` in `B` are equal `text`s.
3. For any two pairs `(i, j)` and `(i', j')` in the set, `i < i'` when,
   and only when, `j < j'`.

A **line map** of `p` between `A` and `B` is a map of `p` between `A`
and `B` with the largest number of pairs: no map of `p` between `A` and
`B` holds more pairs. More than one line map of `p` between `A` and `B`
can exist, and every line map of `p` between `A` and `B` holds the same
number of pairs.

For a line map `M` of `p` between `A` and `B` and an integer `i` from 1
to `m`, **old line `i`** of `p` is the `line` with 1-based line number
`i` of the `utf-8-text` of the file at `p` in `A`. The **new line
number** of old line `i` for `M` is the integer `j` such that `(i, j)`
is in `M`. When no pair in `M` has `i` as its first integer, old line
`i` has no new line number for `M`.

#### Hunk

@term hunk=v1
@cites {
    ontology#tree=v1,
    files#path=v1,
    text#{line=v1, byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1},
    #{line-text=v1, line-map=v1},
}

For a valid `path` `p`, an old `tree` `A`, a new `tree` `B`, and a
`line-map` `M` of `p` between `A` and `B`, let `m` and `n` be the
counts of `line-text`s of `p` in `A` and in `B`. Let `P` be the set
holding every pair of `M` together with `(0, 0)` and `(m + 1, n + 1)`.
For any pair `(i, j)` in `P` other than `(m + 1, n + 1)`, its **next
pair** is the pair in `P` whose first integer is the smallest first
integer in `P` greater than `i`.

Each pair `(i, j)` in `P` whose next pair `(i', j')` satisfies
`i' > i + 1` or `j' > j + 1` defines one **hunk** of `p` between `A`
and `B` for `M`. That hunk has four integers:

- **old start:** `i + 1`;
- **removed count:** `i' - i - 1` (the count of lines the hunk
  removes);
- **new start:** `j + 1`; and
- **added count:** `j' - j - 1` (the count of lines the hunk adds).

When its removed count is 0, a hunk removes no lines; otherwise, the
**lines removed** by the hunk are the `i' - i - 1` consecutive `line`s
of the `utf-8-text` of the file at `p` in `A`, starting at 1-based line
number `i + 1`. When its added count is 0, a hunk adds no lines;
otherwise, the **lines added** by the hunk are the `j' - j - 1`
consecutive `line`s of the `utf-8-text` of the file at `p` in `B`,
starting at 1-based line number `j + 1`.

When no pair in `P` defines a hunk, `p` has one hunk between `A` and
`B` for `M`—with old start 1, removed count 0, new start 1, and added
count 0 (removing and adding no lines)—when any of these three
conditions holds:

1. `A` holds a file at `p`, and `B` does not.
2. `B` holds a file at `p`, and `A` does not.
3. `A` and `B` each hold a file at `p`, their contents are not equal
   `byte-sequence`s, and the content of at least one of those two files
   is not `valid-utf-8`.

No other hunk belongs to `p` between `A` and `B` for `M`. Across all
hunks of `p` between `A` and `B` for any `line-map` of `p` between `A`
and `B`, the sum of removed counts equals `m` minus the number of pairs
in that line map, and the sum of added counts equals `n` minus the
number of pairs in that line map.

@example Suppose an old [tree](sinter:ontology#tree=v1) holds a file
with [line texts](sinter:#line-text=v1) `one`, `two`, `three` and a new
tree holds a file at the same valid [path](sinter:files#path=v1) with
line texts `one`, `2`, `three`, `four`. The unique
[line map](sinter:#line-map=v1) is `{(1, 1), (3, 3)}`: old line 3 has
new line number 3, and old line 2 has no new line number. That line map
produces two hunks: `(old start 2, removed 1, new start 2, added 1)`
and `(old start 4, removed 0, new start 4, added 1)`.

Additional cases (each [line](sinter:text#line=v1) of
[valid UTF-8](sinter:text#valid-utf-8=v1) content ending in LF unless
noted):

| old | new | hunks (old start, removed, new start, added) |
|---|---|---|
| no file | `x`, `y` | `(1, 0, 1, 2)` |
| `x`, `y`, `z` | no file | `(1, 3, 1, 0)` |
| `x` | `x`, `x` | `(2, 0, 2, 1)` or `(1, 0, 1, 1)` |
| `a`, `b` | `b`, `a` | `(1, 1, 1, 0)` and `(3, 0, 2, 1)`, or `(1, 0, 1, 1)` and `(2, 1, 3, 0)` |
| `a`, `b` with CRLF endings | `a`, `b` | none |
| no file | empty file | `(1, 0, 1, 0)` |

#### Change diff

@term change-diff=v1
@cites {
    ontology#tree=v1,
    files#path=v1,
    #{
        commit=v1, default-branch-name=v1, commit-file=v1,
        commit-change=v1, change-base=v1, line-map=v1, hunk=v1,
    },
}

Under a valid binding of `default-branch-name`, when a `commit` `h` has
a `change-base` `b` (the base of the `commit-change` of `h`), a
**change diff** of `h` associates each valid `path` `p` with the
`hunk`s of `p` between the `tree` of `b` (as the old tree) and the
`tree` of `h` (as the new tree) for one `line-map` of `p` between those
two trees, where each commit's tree holds the files defined by
`commit-file`. When `h` has no `change-base` under that binding, `h` has
no change diff.

### Returning hunks and new line numbers

@req give-hunks=v1
@cites {
    conformance#conforming-program=v1,
    ontology#tree=v1,
    files#path=v1,
    #{
        commit=v1, working-tree=v1, repository-read=v1,
        undisturbed-read=v1, commit-file=v1, working-tree-file=v1,
        line-map=v1, hunk=v1,
    },
}

For a valid `path` `p`, an old `tree`, and a new `tree`, when a
conforming program returns `hunk`s of `p` between those trees, new line
numbers of old lines of `p` between those trees, or both in one
execution, the program must use one `line-map` `M` of `p` between those
trees for all of them:

- When returning the `hunk`s of `p` between the two trees, the program
  must return the exact `hunk`s of `p` between those trees for `M`,
  each with its old start, removed count, new start, and added count,
  and—when returning the lines that a hunk removes or adds—those exact
  lines.
- When returning the new line number of an old line `i` of `p` between
  the two trees, or that `i` has no new line number, the program must
  return the new line number of `i` for `M` when `i` has one, and must
  return that `i` has no new line number when `i` has no new line
  number for `M`.

When either tree is the tree of a `commit` (`commit-file`) or of a
`working-tree` (`working-tree-file`), these obligations hold only in an
`undisturbed-read` (a `repository-read`).

### Returning change diffs

@req give-change-diffs=v1
@cites {
    conformance#conforming-program=v1,
    files#path=v1,
    #{
        commit=v1, default-branch-name=v1, commit-change=v1,
        change-base=v1, change-diff=v1, hunk=v1, repository-read=v1,
        undisturbed-read=v1,
    },
}

In an `undisturbed-read` (a `repository-read`), when returning the
`change-diff` of a `commit` `h`, or that `h` has no change diff, under
a valid binding of `default-branch-name`, a conforming program must act
as follows:

- When `h` has a `change-base` (the base of the `commit-change` of `h`)
  under that binding, the program must return one `change-diff` of `h`
  under that binding, with the exact `hunk`s of that `change-diff` for
  each valid `path`.
- When `h` has no `change-base` under that binding, the program must
  return that `h` has no `change-diff`.

### Test vectors

Test vectors for `diffs` live in
[changes.test-vectors.jsonl](changes.test-vectors.jsonl). No group uses
`needs`.

#### Hunk vectors

@schema hunk-vector=v1
@cites {
    conformance#conforming-program=v1,
    data-forms#{
        hex-text=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    ontology#tree=v1,
    files#path=v1,
    text#{byte-sequence=v1, valid-utf-8=v1, utf-8-encoding=v1},
    #{line-map=v1, hunk=v1, give-hunks=v1},
}

`hunk-vector` is a `group-schema` for group `hunks` and tests
`give-hunks`. Each line is a `vector-line` whose meaning follows
`vector-meaning`. Each vector provides an old `tree` and a new `tree`
directly (not read from a commit or a working tree), each holding at
most one file at the valid `path` `f`. A file content `byte-sequence`
appears as a JSON string when it is `valid-utf-8` (representing the
`utf-8-encoding` of that string), or as `{"bytes": "<hex-text>"}` when
it is not `valid-utf-8`.

| field | type | meaning |
|---|---|---|
| `input.old` | string or `{"bytes": string}` (optional) | content of the file at `f` in the old `tree`; present when, and only when, the old tree holds a file at `f` |
| `input.new` | string or `{"bytes": string}` (optional) | content of the file at `f` in the new `tree`; present when, and only when, the new tree holds a file at `f` |
| `values.removed` | integer (`>= 0`) | total lines removed across all `hunk`s of `f` between the two trees for any `line-map` |
| `values.added` | integer (`>= 0`) | total lines added across all `hunk`s of `f` between the two trees for any `line-map` |
| `values.hunks` | array of objects (optional) | present when, and only when, `f` has a unique `line-map` between the two trees; `hunk`s for that line map in increasing order of `old-start` (`[]` when none) |
| `values.hunks[].old-start` | integer (`>= 1`) | old start of the hunk |
| `values.hunks[].removed` | integer (`>= 0`) | removed count of the hunk |
| `values.hunks[].new-start` | integer (`>= 1`) | new start of the hunk |
| `values.hunks[].added` | integer (`>= 0`) | added count of the hunk |
| `values.map` | array of `[i, j]` integer pairs (optional) | present when, and only when, `f` has a unique `line-map` between the two trees; pairs `(i, j)` (`i >= 1`, `j >= 1`) of that line map in increasing order of `i` (`[]` when empty) |

When a conforming program returns `hunk`s of `f` between the two trees,
their total removed and added counts equal `values.removed` and
`values.added`, and when `values.hunks` is present, the returned hunks
match `values.hunks` exactly. When `values.map` is present and a
conforming program returns the new line number of an old line `i` of
`f`, or that old line `i` has no new line number, the program returns
`j` when `[i, j]` is in `values.map` and returns that old line `i` has
no new line number when no pair in `values.map` has `i` as its first
integer.

@example Sample lines testing [give-hunks](sinter:#give-hunks=v1) with
[line-map](sinter:#line-map=v1) and [hunk](sinter:#hunk=v1) for a
unique line map and for multiple line maps
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#hunk-vector=v1","group":"hunks","input":{"new":"x\na\n","old":"a\n"},"note":"a line added before the sole line shifts its new line number","values":{"added":1,"hunks":[{"added":1,"new-start":1,"old-start":1,"removed":0}],"map":[[1,2]],"removed":0}}
{"form":"#hunk-vector=v1","group":"hunks","input":{"new":"b\na\n","old":"a\nb\n"},"note":"two line maps: `a` stays, or `b` stays","values":{"added":1,"removed":1}}
```

#### Change diff vectors

@schema change-diff-vector=v1
@cites {
    conformance#{conforming-program=v1, input=v1, dependence=v1},
    data-forms#{
        hex-text=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    ontology#tree=v1,
    files#path=v1,
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-encoding=v1,
        code-point-order=v1,
    },
    #{
        commit=v1, repository-read=v1, undisturbed-read=v1,
        default-branch-name=v1, default-branch-commit=v1,
        commit-file=v1, commit-change=v1, change-base=v1, line-map=v1,
        hunk=v1, change-diff=v1, give-change-diffs=v1,
    },
}

`change-diff-vector` is a `group-schema` for group `change-diffs` and
tests `give-change-diffs`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector represents an `undisturbed-read`
(a `repository-read`) of a git repository holding only the `commit`s
named in `input.commits`, with no needed git object missing (`input`,
`dependence`). In every vector of this group, each valid `path` has a
unique `line-map` between the tree of the `change-base` and the tree of
`input.last`. A file content `byte-sequence` appears as a JSON string
when it is `valid-utf-8` (representing the `utf-8-encoding` of that
string), or as `{"bytes": "<hex-text>"}` when it is not `valid-utf-8`.

| field | type | meaning |
|---|---|---|
| `input.commits` | object (`string -> array of strings`) | commit graph mapping each short commit name to an array of its parents' short commit names in parent order (`[]` for no parents) |
| `input.trees` | object (`string -> object`) | map with the same short commit name keys as `input.commits`, mapping each commit to an object of `valid path -> file content` pairs for that commit's `tree` (`commit-file`) |
| `input.default` | string | short commit name of the `default-branch-commit` under a valid binding of `default-branch-name` |
| `input.last` | string | short commit name of `commit` `h` |
| `values.diff` | array of objects (optional) | present when, and only when, `h` has a `change-base` (the base of the `commit-change` of `h`) (`[]` when no valid path has a hunk); absent (`values` is `{}`) when `h` has no `change-base`; holds one entry per valid `path` with one or more `hunk`s, in `code-point-order` of `path` |
| `values.diff[].path` | string | valid `path` with one or more `hunk`s in the `change-diff` of `h` |
| `values.diff[].hunks` | array of objects | `hunk`s of `path` in increasing order of `old-start`, each object with `old-start` (integer `>= 1`), `removed` (integer `>= 0`), `new-start` (integer `>= 1`), and `added` (integer `>= 0`) |

When `values.diff` is present and a conforming program returns the
`change-diff` of `h`, or that `h` has no change diff, the program
returns the exact `hunk`s in `values.diff` for each listed valid
`path`, and zero hunks for every other valid `path`. When `values` is
`{}` and a conforming program returns the `change-diff` of `h`, or that
`h` has no change diff, the program returns that `h` has no
`change-diff`.

@example Sample lines testing
[give-change-diffs](sinter:#give-change-diffs=v1) with
[change-diff](sinter:#change-diff=v1),
[change-base](sinter:#change-base=v1), and [hunk](sinter:#hunk=v1) for
a moved file and for a change with no base
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#change-diff-vector=v1","group":"change-diffs","input":{"commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"default":"e","last":"c","trees":{"a":{},"b":{"a.md":"x\n"},"c":{"b.md":"x\n"},"d":{},"e":{"a.md":"x\n"},"f":{},"g":{}}},"note":"a file that moves has the hunks of a removed file and of an added file","values":{"diff":[{"hunks":[{"added":0,"new-start":1,"old-start":1,"removed":1}],"path":"a.md"},{"hunks":[{"added":1,"new-start":1,"old-start":1,"removed":0}],"path":"b.md"}]}}
{"form":"#change-diff-vector=v1","group":"change-diffs","input":{"commits":{"a":[],"b":["a"],"c":["a"],"m1":["b","c"],"m2":["c","b"]},"default":"m2","last":"m1","trees":{"a":{},"b":{"b.md":"b\n"},"c":{"c.md":"c\n"},"m1":{},"m2":{}}},"note":"the change has no base, so it has no diff","values":{}}
```
