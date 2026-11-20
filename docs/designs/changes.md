<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Changes
@design changes=v1
@cites text=v1
@cites files=v1
@cites ontology=v1
@cites data-forms=v1
@cites gitdoc/git
@cites gitdoc/gitrepository-layout
@cites gitdoc/git-worktree
@cites gitdoc/gitglossary
@cites gitdoc/gitdatamodel
@cites gitdoc/gitformat-loose
@cites gitdoc/gitformat-pack
@cites gitdoc/gitformat-commit-graph
@cites gitdoc/git-commit-tree
@cites gitdoc/git-pack-refs
@cites gitdoc/reftable
@cites gitdoc/gitformat-index
@cites gitdoc/git-config
@cites gitdoc/gitignore
@cites gitdoc/git-check-ref-format
@cites gitdoc/git-fetch
@cites gitdoc/git-push
@cites gitdoc/git-remote-ext
@cites gitdoc/githooks
@cites gitdoc/gitattributes
@cites posix/2024
@cites rfc/8259
Specifies the parts of git repositories that Sinter reads: commits, refs, the default branch, the change of a commit and its base, landing commits, the texts of messages, the trees of commits and of working trees, and the hunks between two trees; and requirements for conforming programs that give them and that read git repositories.

Sinter reads git repositories. A git repository holds commits. Each
commit names its parents and a git tree object, which holds files.
Branches point to commits. The default branch is the branch into which
the people who work on the repository bring their work. A change is a
set of commits whose work is to merge into the default branch as one
unit,
such as the commits of a pull request. Two trees, such as the tree of
the base of the change of a commit and the tree of that commit, can
differ in some of their lines: the hunks.

The design takes git repositories as git's documentation defines them.
From the pages git, gitrepository-layout, and git-worktree, it takes the
folder of a repository that its working trees share, `$GIT_COMMON_DIR`,
and the environment variables `GIT_DIR`, `GIT_WORK_TREE`,
`GIT_INDEX_FILE`, `GIT_OBJECT_DIRECTORY`, and
`GIT_ALTERNATE_OBJECT_DIRECTORIES`, with the git repository and the
working tree that git takes from them or from the folder in which a
program starts. From the page gitrepository-layout, it takes the
versions of the repository format, the object database and its
alternates, the file `shallow`, replacement refs, and refs in the files
format. From the page git-worktree, it takes the main working tree and
the linked working trees of a repository, with the refs that a working
tree does not share and the refs in the root of the hierarchy of refs.
From the page gitdatamodel, it takes the parts of a commit object, its
tree, its parents, and its message, and the file types of the entries of
a git tree object. From the pages gitformat-loose and gitformat-pack, it
takes loose objects and packs; from the page gitformat-commit-graph,
commit-graph files; from the page git-commit-tree, the header
`encoding` of a commit object; from the page git-pack-refs, loose refs
and the file `packed-refs`; and from the page reftable, refs in the
reftable format. From the page gitglossary, it takes git objects: commit
objects, git tree objects, blobs, and tag objects; shallow repositories;
and refs, symbolic refs, pseudorefs, branches, remote-tracking branches,
upstream branches, and HEAD, with the names of refs that do not start
with `refs/`, the root names, and the irregular refs among them. From
the page gitformat-index, it takes git's index and its sparse directory
entries. From the page git-config, it takes git's configuration, with
its files, their order, their includes, and the values of settings, and
the settings `extensions.refStorage`, `branch.<name>.remote`,
`branch.<name>.merge`, `core.excludesFile`, `core.ignoreCase`,
`core.precomposeUnicode`, `core.fsmonitor`, `core.sshCommand`,
`remote.<name>.url`, `remote.<name>.pushurl`, `url.<base>.insteadOf`,
and `url.<base>.pushInsteadOf`. From the page gitignore, it takes the
sources of ignore patterns and their rules. From the page
git-check-ref-format, it takes the rules for the names of refs. From the
page git-fetch, it takes fetch refspecs, with the setting
`remote.<name>.fetch` and their use as a mapping, fetches, and the forms
of addresses, with the remote helpers that they choose; from the page
git-push, pushes; and from the page git-remote-ext, addresses of the
form `ext::<command>`. From the page githooks, it takes hooks, and from
the page gitattributes, the files of git attributes. The terms name the
repository format in its versions 0 and 1, as the page
gitrepository-layout gives them; packs in the versions 2 and 3 of the
pack format, with pack indexes in the versions 1 and 2, as the page
gitformat-pack gives them; the reftable format in its versions 1 and 2;
and git's index in its versions 2 to 4.

From Text and notation (`text`), the design takes characters, texts,
bytes, byte sequences, decimal numerals, 0x numerals, hex digits, valid
UTF-8, the text of a byte sequence, UTF-8 encodings, lines, line
numbers, whole numbers, code spans, code point order, and what a
conforming program and a result are. From Files and
paths (`files`), it takes the system, file systems, folder trees,
folders and their folder entries, regular files and their contents,
symbolic links, files of another kind, the bytes that a program takes
from a file, valid paths and their file
names, the files and the folders of the path of a valid path in a folder
tree, and file objects, folder tree objects, and stored folder trees,
the forms in which the vectors write folder trees. From the Ontology
(`ontology`), it takes trees, the default branch, and parameters with
their bindings.

From Data forms (`data-forms`), the design takes test-vector sets, in the
format that its specification `test-vectors` gives: the file that holds
the conformance vectors of the design is one. From POSIX.1-2024, it
takes processes and the shell, the open files of a process, pathnames,
pipes, environment variables, the permissions and the appropriate
privileges of a process, and its user IDs and group IDs.
From RFC 8259, the design takes JSON objects, members, arrays, strings,
numbers, and the literal names `true` and `false`, which the subsections
of its Conformance section name.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| git | the version control system whose repository formats git's documentation gives |
| git repository | a git folder, with the working trees of the repository |
| [git folder](sinter:#git-folder=v1) | the folder of a git repository that its working trees share, `$GIT_COMMON_DIR`, or `$GIT_DIR` when no such folder is set, as the pages git, gitrepository-layout, and git-worktree give it, such as the folder `.git` of its main working tree |
| [working tree](sinter:#working-tree=v1) | the main working tree or a linked working tree of a git repository, as the page git-worktree defines them: the folder tree of the files of the git repository that a person edits, with a folder of its own, which holds its HEAD and, usually, git's index; a git repository can have none, one, or more |
| [folder of a working tree](sinter:#working-tree=v1) | the folder that holds the HEAD and, usually, git's index of one working tree: the git folder for the main working tree, and a folder inside the folder `worktrees` of the git folder for each linked working tree |
| [root folder of a working tree](sinter:#working-tree=v1) | the top folder of a working tree, which usually holds the folder entry `.git` |
| [files of a working tree](sinter:#working-tree=v1) | the files of the folder tree whose root is the root folder of a working tree, other than the file of the folder entry `.git` of that root folder and the files under it; not the same as the files of the tree of the working tree |
| [git configuration](sinter:#git-configuration=v1) | the settings, each with its values in order, that the configuration of git gives for a working tree, or for a git repository, with its git folder and no working tree, as the page git-config defines it, in the environment in which the program started |
| [value from a git repository](sinter:#repository-value=v1) | a value of a setting of a git configuration that the file `config` of the git folder of a git repository, a file `config.worktree` in the folder of a working tree of it, or a file that one of these files includes, in turn, by the includes that the page git-config gives, holds |
| [object database](sinter:#commit=v1) | a folder that holds git objects of a git repository, such as the folder `objects` of its git folder or a folder that its alternates name; the git objects that a git repository holds are those of its object databases |
| git object | a commit object, a git tree object, a blob, or a tag object, as the page gitglossary defines them |
| [commit](sinter:#commit=v1) | a commit object that a git repository holds: it names a git tree object and its parents, in order, and it holds a message |
| merge commit | a commit with two or more parents, as git names it |
| [message of a commit](sinter:#commit=v1) | the commit message, a byte sequence, that a commit object holds, as the page gitdatamodel names it |
| [text of the message of a commit](sinter:#message-text=v1) | the text whose UTF-8 encoding is the message, when the message is valid UTF-8; a message that is not valid UTF-8 has no text |
| [parent, first parent](sinter:#commit=v1) | a commit that a commit names as one of its parents; the first parent is the first of them |
| [git tree object](sinter:#commit-file=v1) | a git object that lists entries; each entry has a name, a mode, and a git object |
| [tree entry, regular-file entry, symbolic-link entry, submodule entry](sinter:#commit-file=v1) | the four kinds of an entry of a git tree object, by the file type that the page gitdatamodel gives for its mode, with the mode 100664 as a regular file |
| blob | a git object that holds a content, which is a byte sequence |
| [reach](sinter:#ancestry=v1) | a commit reaches itself, each of its parents, each parent of each of them, and so on |
| [ancestry](sinter:#ancestry=v1) | the set of the commits that a commit reaches |
| [ref name](sinter:#ref-name=v1) | a text that can be the name of a ref, such as `refs/heads/main` or `HEAD`: it meets the rules of the page git-check-ref-format other than its rule that a ref name holds `/`, and it starts with `refs/` or is a root name of the page gitglossary, such as `ORIG_HEAD`, or one of the irregular refs that it lists |
| [ref](sinter:#ref-commit=v1) | a thing with a ref name, such as `refs/heads/main`, that points to a git object, or that is a symbolic ref, as the page gitglossary defines them |
| [commit of a ref](sinter:#ref-commit=v1) | the commit to which a ref resolves, through the refs that it names in turn, when it resolves to a commit |
| branch | a ref whose name starts with `refs/heads/` |
| remote-tracking branch | a ref whose name starts with `refs/remotes/`, such as `refs/remotes/origin/main`, which records where a branch of the git repository at an address of a remote pointed |
| [upstream](sinter:#default-branch-commit=v1) | the ref that a branch tracks, as the pages gitglossary, git-config, and git-fetch define the upstream branch of a branch |
| [remote, address of a remote](sinter:#remote-transfer=v1) | a remote of a git repository is a name for which its git configuration gives a value of the setting `remote.<name>.url` with that name for `<name>`; its addresses for a fetch and for a push are those that the page git-config gives by `remote.<name>.url` and `remote.<name>.pushurl`, after the rewrite that `url.<base>.insteadOf` and `url.<base>.pushInsteadOf` give |
| [fetch, push](sinter:#remote-transfer=v1) | a transfer of git objects, refs, or both into a git repository from the git repository at an address of a remote for a fetch, or from the git repository into the git repository at an address of a remote for a push |
| [HEAD](sinter:#head-commit=v1) | the ref of a working tree that names a ref, usually a branch, or, when it is detached, points to a git object, usually a commit |
| [head commit](sinter:#head-commit=v1) | the commit of the HEAD of a working tree |
| [git's index](sinter:#working-tree=v1) | the file in which git records the paths of the files that it tracks in a working tree, usually the file `index` in the folder of that working tree |
| [sparse directory entry](sinter:#working-tree-file=v1) | an entry of git's index that names a git tree object and summarizes the paths of that git tree object, as the page gitformat-index defines it |
| [excludes file](sinter:#ignored-path=v1) | the file of ignore patterns that the setting `core.excludesFile` gives, or its default when it has no value, as the page git-config defines it |
| [ignored](sinter:#ignored-path=v1) | a valid path is ignored in a working tree when the ignore patterns of that working tree, as the page gitignore gives them, ignore it; the patterns of a source that is a regular file come from the lines of the text of its content, when that content is valid UTF-8 and that text does not end with a carriage return and holds no U+0000; when the content of such a file does not meet these conditions, its patterns are not specified, nor is whether a path is ignored when the answer depends on them |
| [repository files](sinter:#repository-file=v1) | the files of the git folder of a git repository, of its object databases, and of the folder trees of its working trees, the files to which the symbolic links of the git folder and of its object databases lead, with the files of the folders among them, in turn, and the files of its git configuration, its excludes files, its indexes, and the files of git attributes that the page gitattributes gives other than as files `.gitattributes` in the folders of its working trees, with the symbolic links on their pathnames followed |
| [program file](sinter:#program-file=v1) | a file that the system loads to start a conforming program, or that the act that installed the program put on the system, as that act put them, with the files of the other programs and libraries that the same act put there; not a file that the program or its runtime creates as it runs |
| shallow clone | a git repository whose file `shallow` names commits whose parents it does not hold |
| partial clone | a git repository that leaves out some git objects, which it can take from the git repository at an address of a remote |
| submodule | a git repository whose working tree is in a folder of the working tree of another git repository; a git tree object names it by a submodule entry |
| jj | Jujutsu, a version control program that can keep its data in a git repository |
| colocated jj repository | a git repository whose working tree also holds the folder `.jj`, in which jj keeps its data |
| [branch name](sinter:#branch-name=v1) | a text, such as `main` or `release/2.0`, such that `refs/heads/` followed by it meets the rules of the page git-check-ref-format, other than `HEAD`, a text that starts with `-`, and a text that starts with `refs/` |
| [default branch](sinter:ontology#default-branch=v1) | the branch into which the people who work on a repository bring their work |
| [commit of the default branch](sinter:#default-branch-commit=v1) | under a binding of `default-branch-name` that is a branch name, the commit of the first of the three refs of the default branch, in their order, that exists |
| [parameter](sinter:ontology#parameter=v1), binding | a parameter is a word, such as `default-branch-name`, whose value a design leaves open; a binding of a parameter is a value that configuration gives for it |
| [tree](sinter:ontology#tree=v1) | a set of files, each with a valid path and a content, in which no two files have the same valid path, such as the files at a commit or in a working tree |
| [file of the tree of a commit](sinter:#commit-file=v1) | a file that a regular-file entry gives, through the git tree object of the commit, when its path is a valid path |
| [file of the tree of a working tree](sinter:#working-tree-file=v1) | a regular file that a valid path names from the root folder of a working tree, outside each folder entry `.git`, the folder entry `.jj` of the root folder, and the folders of other git repositories, that git tracks or does not ignore |
| [range](sinter:#commit-range=v1) | the set of the commits that one commit reaches and that another commit does not reach |
| [parents-first order](sinter:#parents-first-order=v1) | the order in which a walk from the commit h of a range from s to h, which takes the parents of each commit in their order, finishes the commits of the range; each commit comes after each of its parents in the range |
| change | a set of commits whose work is to merge into the default branch as one unit, such as the commits of a pull request |
| [change of a commit](sinter:#change-of-a-commit=v1) | under a binding under which the default branch has a commit, for each commit h: the commits that h reaches and that the commit of the default branch does not reach; h is its last commit |
| [last commit of the change of a commit](sinter:#change-of-a-commit=v1) | the commit h of the change of h, such as the commit to which the branch of a pull request points |
| [common ancestor](sinter:#merge-base=v1) | a commit that each of two commits reaches |
| [merge base](sinter:#merge-base=v1) | a common ancestor of two commits that no other common ancestor of the two reaches |
| [base of the change of a commit](sinter:#change-base=v1) | the merge base of a commit h and the commit of the default branch, when there is exactly one |
| squash commit | a commit with one parent that holds the work of the commits of a change |
| fast-forward | a move of a branch to a commit that reaches the commit to which the branch pointed |
| [first-parent line](sinter:#first-parent-line=v1) | a commit, its first parent, the first parent of that commit, and so on, up to a commit that has no parent |
| [landing commit](sinter:#landing-commit=v1) | of a commit c on the first-parent line of a commit d, such as the commit of the default branch: the commit of that first-parent line through which c joined it, which reaches c, and which has no parent or whose first parent does not reach c |
| [line texts](sinter:#line-text=v1) | the texts of the lines of the file of a tree with a valid path, in order; none when the tree has no such file or its content is not valid UTF-8 |
| [line map](sinter:#line-map=v1) | a longest set of pairs of the line numbers of the lines of a file in an old tree and in a new tree that have the same text, in the same order; there can be several |
| [new line number](sinter:#new-line-number=v1) | for a line map, the line number in the new tree of an old line that a pair of the line map holds; an old line that no pair holds has none |
| [hunk](sinter:#hunk=v1) | for a line map, a part of a file where lines differ between an old tree and a new tree: the lines that it removes from the old tree and the lines that it adds in the new tree, with the line numbers where they start; or a hunk with no line, when no line differs and the file is in one tree only, or its two contents differ and one of them is not valid UTF-8 |
| [diff of the change of a commit](sinter:#change-diff=v1) | for each valid path, the hunks between the tree of the base of the change of a commit h and the tree of h, for one line map of that valid path; the change of h has no diff when it has no base |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [byte sequence](sinter:text#byte-sequence=v1) | a finite sequence of bytes |
| [line](sinter:text#line=v1) | one of the runs into which the line endings of a text divide its body; a line holds no line feed, a carriage return right before a line feed is part of the line ending, a byte order mark is on no line, and an empty run at the end of the body is no line |
| [line number](sinter:text#line-number=v1) | the number of a line of a text, from 1 |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [folder tree](sinter:files#folder-tree=v1) | a folder, its root, with the file of each folder entry of each of its folders |
| [regular file](sinter:files#regular-file=v1) | a file that holds a content, which is a byte sequence |
| [symbolic link](sinter:files#symbolic-link=v1) | a file that holds a reference, which can lead to a file or to no file |
| [file of another kind](sinter:files#file-of-another-kind=v1) | a file that is not a folder, a regular file, or a symbolic link, such as a pipe |
| [repository read](sinter:#repository-read=v1) | an operation in which a program takes, from a git repository or from a working tree of it, things that the terms here define, such as a commit, the files of a tree, or the hunks of a valid path, to give them or to use them; a fetch, a push, and a change of a ref that the program makes are not one, and each fetch into the git repository that the program makes, itself or through any program that it uses, during a read is part of that read; no push, and no other change of a ref, is part of one; a read lasts from the first time that the program takes bytes, or uses a pathname to reach or look for a repository file, for it until the last time that it does one of these; a program gives a thing in a read when it gives what that read took |
| [undisturbed repository read](sinter:#undisturbed-read=v1) | a repository read during which no process, the program that makes it included, other than in an own change of the read when the file of that change is not a file of a working tree, creates, deletes, or changes a repository file from which the read takes bytes, or changes which file a pathname names, or whether it names one, when the read uses that pathname to reach or look for a repository file |
| [own change of a repository read](sinter:#undisturbed-read=v1) | the creation, the deletion, or the change of one file by the program that makes the read, itself or through any program that it uses, when that file is one of these: a file of a loose object or a pack that the program creates in the read, with the files that are for that pack alone, or a folder of the folder tree of an object database; a commit-graph file in a fetch that is part of the read; git's index, a file that its format names, or the folder that holds the index, when the index holds an entry for the same byte paths after the change as before it; or a lock file or a temporary file that the program creates in one of these folders and deletes, or renames to one of the files before it; a change of one of these folders counts only when each folder entry that the change creates, deletes, or changes names one of these files that is not a folder, or a folder that the program created in the read; a file that holds a ref, the file `FETCH_HEAD` or `shallow`, and the file `info/alternates` give none, not even as such a temporary file; an own change keeps a read undisturbed only when its file is not a file of a working tree |
| [conforming program](sinter:text#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |

## 2. Git repositories, changes, and hunks

### 2.1 Git repositories

A git repository has a git folder, which the term `git-folder` defines,
and zero or more working trees, which the term `working-tree` defines.
The object databases of a git repository hold its git objects: commit
objects, git tree objects, blobs, and tag objects. A working tree holds
the files that a person edits, with its own HEAD and git's index.

A program reads a git repository in a repository read, which the term
`repository-read` defines. Its results come from the git objects and the
refs of the git repository, from the git configuration, which the term
`git-configuration` defines, and, for a working tree, from the files on
disk, git's index, and the ignore rules. The term `commit` defines which
git objects a git repository holds and the parents of its commits, also
in a shallow clone, which leaves out the parents of some commits. A
partial clone leaves out some git objects, which git can take from the
git repository at an address of a remote. A program can take them by a
fetch during a repository read, which the term `repository-read` makes
part of that read.

Jujutsu, also named jj, is a version control program that can keep its
data in a git repository. A colocated jj repository is a git repository
whose working tree also holds the folder `.jj`, in which jj keeps its
own data. A program reads a colocated jj repository as a git repository,
and the term `working-tree-file` keeps the files of jj out of the tree
of the working tree.

### 2.2 Commits, ranges, and their order

The term `commit` defines the parents of a commit, in their order, and
its first parent. Git makes a commit with two or more parents when a
person joins the histories of two or more branches in one commit. The
term `ancestry` defines the commits that a commit reaches. The term
`commit-range` defines the range from a commit, or from no commit, to a
commit h, and the term `parents-first-order` defines an order of a range
that comes from a walk of the parents of its commits, not from the dates
of the commits.

Example: in the history below, each commit names its parents to its
left. The commit `f` has two parents: its first parent `c` and its
second parent `e`. The branch `main` points to `g`, and the branch
`feature` pointed to `e` before git made `f`.

```
a <- b <- c <------- f <- g      main
      \             /
       d <------- e              feature
```

The range from `c` to `e` is `d` and `e`, in this parents-first order.
The range from `b` to `g` holds `c`, `d`, `e`, `f`, and `g`. Its
parents-first order is `c`, `d`, `e`, `f`, `g`: the walk starts at `g`,
walks `f`, then the first parent `c` of `f`, then the second parent `e`
of `f`, and `d` before `e`.

The term `commit` defines the message of a commit, and the term
`message-text` defines its text.

### 2.3 Branches, HEAD, and the default branch

A branch is a ref under `refs/heads/`, such as `refs/heads/main`. A
remote-tracking branch is a ref under `refs/remotes/`, such as
`refs/remotes/origin/main`, which records where a branch of the git
repository at an address of a remote pointed when git last fetched it. A
ref can also name another ref, as a symbolic ref does. The term
`ref-commit` defines the commit of a ref, and the term `head-commit`
defines the HEAD and the head commit of a working tree. For example, in
a new repository the HEAD names a branch that does not exist yet, so the
working tree has no head commit. In a colocated jj repository, the HEAD
of the working tree is often detached.

The upstream of a branch is the ref that it tracks, often a
remote-tracking branch. Item 1 of the term `default-branch-commit` takes
it as the pages git-config and git-fetch define it, from the settings
`branch.<name>.remote` and `branch.<name>.merge` and from the fetch
refspecs of the remote. For example, when
`branch.main.remote` is `origin`, `branch.main.merge` is
`refs/heads/main`, and the one fetch refspec of `origin` is
`+refs/heads/*:refs/remotes/origin/*`, the upstream of `main` is
`refs/remotes/origin/main`.

The parameter `default-branch-name` gives the name of the default
branch. A binding of it names the default branch when it is a branch
name, which the term `branch-name` defines. So `main`, `release/2.0`,
and `@` are branch names, and `a..b`, `.hidden`, `topic.lock`, `a b`,
`HEAD`, `-x`, and `refs/heads/main` are not. The term
`default-branch-commit` gives the commit of the default branch under a
binding. For example, under the binding `main`, when `main` has the
upstream `refs/remotes/origin/main` and that ref points to a commit, the
commit of the default branch is that commit.

### 2.4 The change of a commit and its base

A change is a set of commits whose work is to merge into the default
branch as one unit, such as the commits of a pull request. The term
`change-of-a-commit` defines the change of a commit h and its last
commit, h. When the commit of the default branch is the commit on which
a pull request is to merge, the change of the last commit of the pull
request holds the commits of that pull request. In a working tree, the
commit h is often the head commit. When a person makes, on the branch of
a pull request, a commit whose second parent is the commit of the
default branch, no commit that the commit of the default branch reaches
is in the change of the last commit of the pull request.

The term `merge-base` defines the common ancestors and the merge bases
of two commits, and the term `change-base` defines the base of the
change of a commit.

In the example of section 2.2, before git made `f`, the default branch
pointed to `c`. The change of `e` holds `d` and `e`, and its base is
`b`. If the default branch pointed to `g`, the change of `e` would hold
no commit, and its base would be `e`.

Two commits can have no merge base, when their histories share no
commit. They can also have more than one, after merge commits whose
parents cross. For example, the commits `b` and `c` each have the parent
`a`. The commit `m1` has the parents `b` and `c`, and the commit `m2`
has the parents `c` and `b`. The common ancestors of `m1` and `m2` are
`a`, `b`, and `c`. Both `b` and `c` reach `a`, so the merge bases of
`m1` and `m2` are `b` and `c`, and the change of `m1`, while the default
branch points to `m2`, has no base.

### 2.5 First-parent lines and landing commits

The term `first-parent-line` defines the first-parent line of a commit.
A merge commit, as git names it, is a commit with two or more parents.
When a person brings the work of a change into the default branch with a
merge commit, git makes the commit to which the default branch pointed
the first parent of the merge commit, and the last commit of the change
its second parent. So the first-parent line of the commit of the default
branch passes through each merge commit that brought work into it, and
not through the commits whose work that merge commit brought.

For a commit c that a commit d reaches, the landing commit of c on the
first-parent line of d, which the term `landing-commit` defines, is the
commit of that first-parent line through which c joined it.

In the example of section 2.2, the first-parent line of `g` is `g`, `f`,
`c`, `b`, and `a`. The landing commit of `d` and of `e` on that
first-parent line is the merge commit `f`. The landing commit of `c` is
`c` itself. When the work of a change comes into the default branch as
one squash commit, that squash commit is on the first-parent line, and
it is its own landing commit. When the default branch fast-forwards to
the last commit of a change, and the change holds no merge commit, each
commit of the change is on the first-parent line, and it is its own
landing commit.

### 2.6 The files of a tree

The term `tree` of the Ontology defines a tree. A commit gives one tree,
the tree of the commit, and a working tree gives one tree, the tree of
the working tree.

The term `commit-file` defines the files of the tree of a commit. They
come from the entries of the git tree object of the commit, and the file
type that the mode of an entry gives is its kind. For example, an entry
with the mode 100644, or 100755 for an executable file, is a
regular-file entry and gives a file; an entry with the mode 40000, which
the page gitdatamodel writes as 040000, is a tree entry, whose git tree
object lists more entries; and an entry with the mode 120000, a symbolic
link, or 160000, a submodule, gives no file.

The term `working-tree-file` defines the files of the tree of a working
tree. They come from the files on disk, git's index, and the ignore
rules, which the term `ignored-path` defines. For example, a file that
git tracks and that a person changed after the last commit has its new
content, whatever git's index records about it.

Example: the root folder of a working tree holds `.git`, `.gitignore`
with the pattern `build/`, `a.md`, a symbolic link `link` to the folder
`docs`, the folder `docs` with `b.md`, the folder `build` with `out.md`,
and the folder `lib` of a submodule, with its file `.git` and its file
`c.md`. Git's index holds `.gitignore`, `a.md`, `docs/b.md`, and `lib`.
The files of the tree of the working tree are `.gitignore`, `a.md`, and
`docs/b.md`: the term `working-tree-file` leaves out the folder `.git`
and the files of `lib`, which holds an entry `.git`; `link` is a
symbolic link; and `build/out.md` is ignored and not in git's index.

### 2.7 Line texts, line maps, and hunks

Two trees, an old tree and a new tree, can hold a file with the same
valid path. The term `line-text` defines the line texts of a valid path
in a tree. A line holds no line ending, so two contents that differ only
in their line endings, or only in a byte order mark, give the same line
texts.

The term `line-map` defines a line map of a valid path between the two
trees. Several line maps can exist when lines repeat or change their
order, and a program can give the hunks of any one of them. The term
`hunk` defines the hunks of the valid path for a line map, and the term
`new-line-number` defines the new line number of an old line.

Example: the old content is `one`, `two`, `three`, each line with a line
ending. The new content is `one`, `2`, `three`, `four`. The one line map
is the pairs (1, 1) and (3, 3). There are two hunks: one with the old
start 2, one line removed, the new start 2, and one line added; and one
with the old start 4, no line removed, the new start 4, and one line
added. The old line 3 has the new line number 3, and the old line 2 has
none.

| old | new | hunks: old start, removed, new start, added |
|---|---|---|
| no file | `x`, `y` | 1, 0, 1, 2 |
| `x`, `y`, `z` | no file | 1, 3, 1, 0 |
| `x` | `x`, `x` | 2, 0, 2, 1, or 1, 0, 1, 1 |
| `a`, `b` | `b`, `a` | 1, 1, 1, 0 and 3, 0, 2, 1, or 1, 0, 1, 1 and 2, 1, 3, 0 |
| `a`, `b`, with carriage returns | `a`, `b` | none |
| no file | an empty file | 1, 0, 1, 0 |

A file that moves to another valid path has the hunks of a file removed
at its old path and of a file added at its new path. The term
`change-diff` defines a diff of the change of a commit.

### 2.8 What a program guarantees

The requirement `leave-repositories-unchanged` states what a conforming
program must not change during each repository read. The requirements
`read-only-repository-files`, `gain-no-repository-privileges`, and
`follow-no-working-tree-links` state what it must not do in each
repository read, and the requirement `run-no-configured-programs` states
what it must not run. What a program gives in a repository read that is
not undisturbed, as the term `undisturbed-read` defines it, is not
specified, and these requirements still bind it.

## 3. Parameters

### 3.1 `default-branch-name`

The parameter `default-branch-name` gives the name of the default branch
of a git repository. A binding of it is a text. The term
`default-branch-commit` gives the default branch and its commit under a
binding.

## 4. Definitions

### 4.1 Git folders

@term git-folder=v1
@cites {
    gitdoc/git,
    gitdoc/gitrepository-layout,
    gitdoc/git-worktree,
    gitdoc/git-config,
    files#{folder=v1},
    text#{code-span=v1},
}

The git folder of a git repository is the folder that holds the files of
the git repository that its working trees share: the folder that the
pages git, gitrepository-layout, and git-worktree name
`$GIT_COMMON_DIR`, or `$GIT_DIR` when no such folder is set, such as the
folder `.git` of its main working tree. A git repository is in the
version 0 or the version 1 of the repository format, as the page
gitrepository-layout gives these versions. The ref storage format of the
git repository, `files` or `reftable`, is the one that the page
git-config gives by the setting `extensions.refStorage`.

### 4.2 Working trees

@term working-tree=v1
@cites {
    gitdoc/git,
    gitdoc/gitrepository-layout,
    gitdoc/git-worktree,
    gitdoc/gitformat-index,
    posix/2024,
    files#{folder=v1, folder-tree=v1},
    text#{code-span=v1},
    #{git-folder=v1},
}

A working tree of a git repository is its main working tree or one of
its linked working trees, as the page git-worktree defines them. It has
a root folder, which is the root of the folder tree of the files that a
person edits, and a folder of its own, which holds the HEAD of that
working tree. The folder of the main working tree is the git folder. The
folder of each linked working tree is its folder inside the folder
`worktrees` of the git folder, as the pages git-worktree and
gitrepository-layout give it. Git's index of a working tree is the file
`index` in the folder of that working tree, other than for the working
tree that git takes in the environment in which the program started, by
the environment variables `GIT_DIR` and `GIT_WORK_TREE` or else from the
folder in which the program started, as the page git gives it: when the
environment variable `GIT_INDEX_FILE` is set there, git's index of that
working tree is the file that it names. It is in one of the versions 2
to 4 of the format that the page gitformat-index gives, with the files
that this format names, such as the shared index of a split index. The
files of a working tree are the files of the folder tree whose root is
its root folder, other than the file of the folder entry `.git` of the
root folder and, when that file is a folder, the files of the folder
tree whose root is that folder.

### 4.3 Git configurations

@term git-configuration=v1
@cites {
    gitdoc/git-config,
    posix/2024,
    files#{symbolic-link=v1},
    text#{code-span=v1},
    #{git-folder=v1, working-tree=v1},
}

The git configuration of a working tree of a git repository is the set
of the settings, each with its values in order, that the configuration
of git gives for that working tree, as the page git-config defines it,
in the environment in which the program started. The git configuration
of a git repository is the set of the settings that the configuration of
git gives in the same way for the git repository, with its git folder
and with no working tree. The files of a git configuration are the files
that the pathnames from which the page git-config takes its settings
name, and the files that their includes name, in turn, whether or not
the condition of an include holds, each with the symbolic links on its
pathname followed and whether or not a file is there.

### 4.4 Commits

@term commit=v1
@cites {
    gitdoc/git,
    gitdoc/gitrepository-layout,
    gitdoc/gitglossary,
    gitdoc/gitdatamodel,
    gitdoc/gitformat-loose,
    gitdoc/gitformat-pack,
    posix/2024,
    text#{byte-sequence=v1, code-span=v1},
    #{git-folder=v1},
}

The object databases of a git repository are the folder `objects` of its
git folder and each folder that the alternates of one of its object
databases name, in turn, as the page gitrepository-layout defines object
databases and alternates. For the git repository that git takes in the
environment in which the program started, by the environment variable
`GIT_DIR` or else from the folder in which the program started, as the
page git gives it, the folder that the environment variable
`GIT_OBJECT_DIRECTORY` names there, when it is set, takes the place of
the folder `objects`, and each folder that the environment variable
`GIT_ALTERNATE_OBJECT_DIRECTORIES` names there is also an object
database. A git repository holds a git object when one of its object
databases holds that git object, as a loose object or in a pack, in the
versions 2 and 3 of the pack format with a pack index in the versions 1
and 2, as the pages gitformat-loose and gitformat-pack define loose
objects, packs, and pack indexes. A commit of a git repository is a
commit object, as the page gitglossary defines it, that the git
repository holds. A commit names one git tree object, the git tree
object of the commit, and its parents, in the order in which it names
them, and it holds a message, a byte sequence, as the page gitdatamodel
gives these parts of a commit. The first of its parents is its first
parent. A commit that the file `shallow` of the git folder names has no
parents, as the pages gitglossary and gitrepository-layout define
shallow repositories and that file. When a commit is not named by the
file `shallow`, and its commit object names, as a parent, a git object
that is not a commit of the git repository, the parents of that commit
are not specified. The content of a blob, the entries of a git tree
object, and the git tree object and the message of a commit are those
that the git object itself holds, and so are the parents of a commit,
apart from the rule of the file `shallow`: no replacement ref, which is
a ref whose name starts with `refs/replace/`, has an effect on them.

### 4.5 The texts of messages

@term message-text=v1
@cites {
    gitdoc/git-commit-tree,
    text#{
        text=v1, valid-utf-8=v1, text-of-a-byte-sequence=v1, code-span=v1,
    },
    #{commit=v1},
}

The text of the message of a commit is the text of the byte sequence of
that message, when that byte sequence is valid UTF-8. The message of a
commit whose byte sequence is not valid UTF-8 has no text. The header
`encoding` of the commit object, which the page git-commit-tree gives,
has no effect on the text of its message.

### 4.6 Ancestry

@term ancestry=v1
@cites #{commit=v1}

The ancestry of a commit c is the smallest set of commits that holds c
and that holds each parent of each commit that it holds. A commit c
reaches each commit of its ancestry, c included, and no other commit.

### 4.7 Ref names

@term ref-name=v1
@cites {
    gitdoc/git-check-ref-format,
    gitdoc/gitglossary,
    text#{text=v1, code-span=v1},
}

A ref name is a text that meets the rules of the page
git-check-ref-format for the names of refs, other than its rule that a
ref name holds `/`, and that starts with `refs/` or is a root name: a
name of a ref in the root of the hierarchy of refs that meets the rules
of the page gitglossary for such names, such as `HEAD` or `ORIG_HEAD`,
or that is one of the irregular refs in the root of that hierarchy that
the page gitglossary lists.

### 4.8 The commits of refs

@term ref-commit=v1
@cites {
    gitdoc/gitrepository-layout,
    gitdoc/gitglossary,
    gitdoc/git-worktree,
    gitdoc/git-pack-refs,
    gitdoc/reftable,
    text#{code-span=v1},
    #{git-folder=v1, working-tree=v1, commit=v1, ref-name=v1},
}

A ref of a git repository, or of a working tree of it, has a ref name,
and it points to a git object, or it is a symbolic ref, as the page
gitglossary defines refs and symbolic refs. The refs that a folder holds
are those that the ref storage format of the git repository gives for
that folder, as the pages define that format: for the format `files`,
its loose refs, with the refs in the root of the hierarchy of refs, as
the pages gitrepository-layout, git-pack-refs, and git-worktree give
them, and, for the git folder, each ref of its file `packed-refs` whose
ref name no loose ref of the git folder has, as the page git-pack-refs
gives it; for the format `reftable`, in its versions 1 and 2, the refs
that the stack of tables of that folder gives, as the page reftable
gives them. The own refs of a working tree are the refs that the page
git-worktree, in its section on refs, gives as not shared between
working trees. A working tree holds its own refs from the folder of that
working tree and each other ref from the git folder, and the git
repository holds each ref from the git folder. A ref exists when the git
repository, or the working tree, holds a ref with that ref name,
whatever it points to or names. The commit of a ref is the git object to
which that ref resolves, through the refs of the same git repository or
working tree that it names in turn, when that git object is a commit of
the git repository. A symbolic ref that names no ref that exists
resolves to no git object. A ref that does not exist, or that resolves
to no commit of the git repository, has no commit. The commit of a
pseudoref, as the page gitglossary defines pseudorefs, is not specified.

### 4.9 Head commits

@term head-commit=v1
@cites {gitdoc/gitglossary, #{working-tree=v1, ref-commit=v1}}

The HEAD of a working tree is a ref of that working tree, in the folder
of that working tree, as the page gitglossary defines it: it names a
ref, or, when it is detached, it points to a git object. The head commit
of a working tree is the commit of its HEAD. A working tree whose HEAD
has no commit has no head commit.

### 4.10 Branch names

@term branch-name=v1
@cites {
    gitdoc/git-check-ref-format,
    text#{text=v1, character=v1, code-span=v1},
}

A branch name is a text b that meets each of these conditions:

1. The text that is `refs/heads/` followed by b meets the rules of the
   page git-check-ref-format for the names of refs.
2. b is not `HEAD`, and it does not start with the character `-`.
3. b does not start with `refs/`.

### 4.11 The commit of the default branch

@term default-branch-commit=v1
@cites {
    gitdoc/gitglossary,
    gitdoc/git-config,
    gitdoc/git-fetch,
    ontology#{default-branch=v1, parameter=v1},
    text#{code-span=v1, text=v1},
    #{git-configuration=v1, ref-commit=v1, branch-name=v1},
}

Under a binding of the parameter `default-branch-name` that is a branch
name b, the default branch of a git repository is the branch whose ref
name is `refs/heads/` followed by b, and these are the three refs of the
default branch, in this order:

1. the upstream of b: the ref whose name the pages gitglossary,
   git-config, in its entries for the settings `branch.<name>.remote`
   and `branch.<name>.merge`, and git-fetch give as the upstream branch
   of the branch b, from these two settings, with b for `<name>`, in the
   git configuration of the git repository, and, when the value of
   `branch.<name>.remote` is not `.`, from the values of the setting
   `remote.<name>.fetch`, with that value for `<name>`, as fetch
   refspecs used as a mapping. When the git configuration gives no such
   ref name, b has no upstream. When the setting `branch.<name>.merge`,
   with b for `<name>`, has more than one value in the git configuration
   of the git repository, the upstream of b, and so the commit of the
   default branch, are not specified.
2. the ref whose name is `refs/heads/` followed by b.
3. the ref whose name is `refs/remotes/origin/` followed by b.

The commit of the default branch is the commit of the first of these
three refs that exists in the git repository. When none of them exists,
or when the first of them that exists has no commit, the default branch
has no commit. Under a binding of `default-branch-name` that is not a
branch name, the default branch has no commit.

### 4.12 The files of the tree of a commit

@term commit-file=v1
@cites {
    gitdoc/gitglossary,
    gitdoc/gitdatamodel,
    ontology#{tree=v1},
    files#{path=v1},
    text#{byte-sequence=v1, byte=v1, utf-8-encoding=v1, 0x-numeral=v1},
    #{commit=v1},
}

A git tree object lists entries, as the pages gitglossary and
gitdatamodel define git tree objects. Each entry has a name, which is a
byte sequence, a mode, and a git object. Each entry is of one of four
kinds, by the file type that the page gitdatamodel gives for its mode:

1. a tree entry, for the type directory: it names a git tree object;
2. a regular-file entry, for the types regular file and executable
   file, and for the mode 100664: it names a blob;
3. a symbolic-link entry, for the type symbolic link;
4. a submodule entry, for the type gitlink.

The entries of a git tree object T, each with its byte path, which is a
byte sequence, are these: each entry that T lists, with its name as its
byte path; and, for each tree entry D among them, each entry of the git
tree object that D names, with the byte path of D, then the byte 0x2F,
then its byte path in that git tree object.

The files of the tree of a commit, and their contents, are the same
whether or not the git repository holds the git objects that they come
from. The files of the tree of a commit are these, and no others: for
each regular-file entry E of the git tree object of the commit whose
byte path is the UTF-8 encoding of a valid path p, the file whose valid
path is p and whose content is the content of the blob that E names.
When two of the entries of the git tree object of a commit have one byte
path, the files of the tree of that commit are not specified.

### 4.13 Ignored paths

@term ignored-path=v1
@cites {
    gitdoc/git-config,
    gitdoc/gitignore,
    posix/2024,
    files#{symbolic-link=v1, path=v1, regular-file=v1},
    text#{
        code-span=v1, line=v1, text-of-a-byte-sequence=v1, valid-utf-8=v1,
        carriage-return=v1, u-numeral=v1,
    },
    #{git-folder=v1, working-tree=v1, git-configuration=v1},
}

The excludes file of a working tree is the file that the setting
`core.excludesFile` gives in the git configuration of the working tree,
or, when that setting has no value there, the file that the page
git-config gives as its default, in the environment in which the program
started, as the page git-config defines that setting.

A valid path is ignored in a working tree when the patterns of the
sources that the page gitignore gives for the paths of a working tree,
other than the command line, ignore it, by the rules of that page, as
for a file that git's index does not hold. Among these sources, the file
`info/exclude` of the git folder and the excludes file are the files
that their pathnames name, with the symbolic links on these pathnames
followed. The patterns of a source that is a regular file come from the
lines of the text of its content, as the term `text#line` gives the
lines of a text, by the rules of the page gitignore, when that content
is valid UTF-8 and that text does not end with a carriage return and
holds no U+0000. When a source is a regular file whose content does not
meet these conditions, its patterns are not specified, and whether a
valid path is ignored in the working tree is not specified when, by the
rules of the page gitignore, the answer depends on the patterns of that
source. When the setting `core.ignoreCase` of the git configuration of
the working tree is true, as the page git-config gives the value of a
setting and the values of booleans, a pattern also matches each valid
path that differs only in the case of the letters from `A` to `Z` from a
valid path that the pattern matches.

### 4.14 The files of the tree of a working tree

@term working-tree-file=v1
@cites {
    gitdoc/gitformat-index,
    gitdoc/git-config,
    ontology#{tree=v1},
    files#{
        folder-tree=v1, folder=v1, regular-file=v1, path=v1,
        path-file=v1,
    },
    text#{
        text=v1, utf-8-encoding=v1, valid-utf-8=v1, code-span=v1, byte=v1,
        0x-numeral=v1,
    },
    #{
        working-tree=v1, git-configuration=v1, ignored-path=v1, commit=v1,
        commit-file=v1,
    },
}

The files of the tree of a working tree are these, and no others: for
each valid path p whose last file name names a regular file F in the
folder tree whose root is the root folder of the working tree, and that
meets each of these conditions, the file whose valid path is p and
whose content is the content of F.

1. No file name of p is `.git`, and the first file name of p is not
   `.jj`.
2. No folder of the path of p, other than the root, holds a folder entry
   whose entry name is the UTF-8 encoding of the text `.git`.
3. Git's index of the working tree holds an entry for the UTF-8
   encoding of p, or p is not ignored in the working tree.

Git's index holds an entry for a byte path b when it has an entry whose
path is b, or a sparse directory entry that summarizes b, as the page
gitformat-index defines these entries, whether or not the git repository
holds the git tree object that the sparse directory entry names.

When the setting `core.precomposeUnicode` of the git configuration of
the working tree is true, as the page git-config gives the values of
booleans, and the entry name of a regular file of that folder tree, or
of a folder on the way to it, is valid UTF-8 and holds a byte of 0x80 or
more, whether that regular file gives a file of the tree of the working
tree, and with which valid path, is not specified.

### 4.15 Ranges

@term commit-range=v1
@cites #{commit=v1, ancestry=v1}

For two commits s and h of a git repository, the range from s to h is
the set of the commits that h reaches and that s does not reach. The
range from no commit to h is the set of the commits that h reaches.

### 4.16 Parents-first orders

@term parents-first-order=v1
@cites #{commit=v1, commit-range=v1}

Let R be the range from a commit s, or from no commit, to a commit h. To
walk a commit c of R is to start c; then to take each parent of c in
turn, in the order of the parents, and to walk that parent when it is in
R and is not started when the walk takes it; and then to finish c. The
walk of R walks h when h is in R, and walks no commit when R is empty.
The parents-first order of R is the order in which the walk of R
finishes the commits of R. So each commit of R comes after each of its
parents that is in R.

### 4.17 The change of a commit

@term change-of-a-commit=v1
@cites {
    ontology#{default-branch=v1, parameter=v1},
    text#{code-span=v1},
    #{commit=v1, commit-range=v1, default-branch-commit=v1},
}

Under a binding of `default-branch-name` under which the default branch
of a git repository has a commit d, the change of a commit h of the git
repository, under that binding, is the range from d to h. Its commits
are the commits of that range, and its last commit is h, also when it
holds no commit.

### 4.18 Merge bases

@term merge-base=v1
@cites #{commit=v1, ancestry=v1}

A common ancestor of two commits is a commit that each of the two
reaches. A merge base of two commits is a common ancestor of the two
that no other common ancestor of the two reaches.

### 4.19 The base of the change of a commit

@term change-base=v1
@cites {
    ontology#{parameter=v1},
    text#{code-span=v1},
    #{
        commit=v1, change-of-a-commit=v1, merge-base=v1,
        default-branch-commit=v1,
    },
}

The base of the change of a commit h under a binding of
`default-branch-name` is the merge base of h and the commit of the
default branch under that binding, when these two commits have exactly
one merge base. When they have no merge base, or more than one, the
change of h has no base. When the default branch has no commit under
that binding, the change of h has no base.

### 4.20 First-parent lines

@term first-parent-line=v1
@cites #{commit=v1}

The first-parent line of a commit c is the sequence of commits that
starts with c, in which each other commit is the first parent of the
commit right before it, and whose last commit has no parent.

### 4.21 Landing commits

@term landing-commit=v1
@cites #{commit=v1, ancestry=v1, first-parent-line=v1}

For a commit d and a commit c that d reaches, the landing commit of c on
the first-parent line of d is the commit m of that first-parent line
that reaches c, and that has no parent or whose first parent does not
reach c. The commits of that first-parent line that reach c come first
in it, so m is the last of them. A commit that d does not reach has no
landing commit on the first-parent line of d.

### 4.22 Line texts

@term line-text=v1
@cites {
    ontology#{tree=v1},
    files#{path=v1},
    text#{
        text=v1, line=v1, line-number=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1, whole-number=v1,
    },
}

For a valid path p and a tree A, when A has a file whose valid path is p
and whose content is valid UTF-8, the line texts of p in A are the texts
of the lines of the text of that content, in the order of their line
numbers: line text k of p in A is the text of the line whose line number
is k. Otherwise, p has no line text in A.

### 4.23 Line maps

@term line-map=v1
@cites {
    ontology#{tree=v1},
    files#{path=v1},
    text#{text=v1, whole-number=v1},
    #{line-text=v1},
}

For a valid path p, an old tree A, and a new tree B, let m be the number
of the line texts of p in A, and let n be the number of the line texts
of p in B. A map of p between A and B is a set of pairs (i, j) of whole
numbers, with i from 1 to m and j from 1 to n, such that line text i of
p in A and line text j of p in B are the same text, and such that, for
each pair (i, j) and each pair (i′, j′) of the set, i < i′ when, and
only when, j < j′. A line map of p between A and B is a map of p
between A and B with the greatest number of pairs: no map of p between
A and B has more pairs. There can be more than one line map of p
between A and B, and each of them has the same number of pairs.

### 4.24 New line numbers

@term new-line-number=v1
@cites {
    ontology#{tree=v1},
    files#{path=v1},
    text#{
        line=v1, line-number=v1, whole-number=v1,
        text-of-a-byte-sequence=v1,
    },
    #{line-map=v1},
}

For a valid path p, an old tree A, a new tree B, and a line map M of p
between A and B, the old line i of p is line i of the text of the
content of the file of A whose valid path is p. The
new line number of the old line i for M is the whole number j such that
M holds the pair (i, j). An old line i of p that no pair of M holds as
its first number has no new line number for M.

### 4.25 Hunks

@term hunk=v1
@cites {
    ontology#{tree=v1},
    files#{path=v1},
    text#{
        line=v1, line-number=v1, byte-sequence=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1, whole-number=v1,
    },
    #{line-text=v1, line-map=v1},
}

For a valid path p, an old tree A, a new tree B, and a line map M of p
between A and B, let m and n be the numbers of the line texts of p in A
and in B. Let P be the set of the pairs of M, with the pair (0, 0) and
the pair (m + 1, n + 1). The next pair of a pair (i, j) of P, other than
(m + 1, n + 1), is the pair of P whose first number is the least first
number of P that is greater than i. Each pair (i, j) of P whose next
pair (i′, j′) has i′ > i + 1 or j′ > j + 1 gives p one hunk between A
and B for M, which has four whole numbers: its old start, i + 1; the
number of the lines that it removes, i′ − i − 1; its new start, j + 1;
and the number of the lines that it adds, j′ − j − 1. The lines that
such a hunk removes are the lines of the text of the content of the file
of A with the valid path p, from the line whose line number is its old
start, as many as it removes. The lines that it adds are the lines of
the text of the content of the file of B with the valid path p, from the
line whose line number is its new start, as many as it adds.

When the pairs of P give p no hunk, p has one hunk between A and B for
M, with the old start 1, no line that it removes, the new start 1, and
no line that it adds, when one of these holds:

1. A has a file whose valid path is p, and B has none.
2. B has a file whose valid path is p, and A has none.
3. A and B each have a file whose valid path is p, the contents of the
   two are not the same byte sequence, and the content of one of them is
   not valid UTF-8.

The hunks of p between A and B for M are the hunks that these rules
give, and no others. The hunks of p between A and B for each line map
remove the same number of lines, m less the number of the pairs of a
line map, and add the same number of lines, n less that number.

### 4.26 The diff of the change of a commit

@term change-diff=v1
@cites {
    ontology#{tree=v1},
    files#{path=v1},
    #{
        change-of-a-commit=v1, change-base=v1, commit-file=v1,
        line-map=v1, hunk=v1,
    },
}

When the change of a commit h has a base, a diff of the change of h
gives, for each valid path p, the hunks of p between the tree of that
base, as the old tree, and the tree of h, as the new tree, for one line
map of p between these two trees. When the change of h has no base, it
has no diff.

### 4.27 Repository reads

@term repository-read=v1
@cites {
    posix/2024,
    ontology#{tree=v1},
    files#{path=v1, taken-byte=v1},
    #{
        working-tree=v1, commit=v1, ref-commit=v1, hunk=v1,
        remote-transfer=v1, repository-file=v1,
    },
}

A repository read is an operation in which a program takes, from a git
repository or from a working tree of it, one or more things that a term
of this design defines, such as a commit, the files of a tree, or the
hunks of a valid path, to give them or to use them. A fetch, a push, and
a change of a ref that the program makes, with the git objects that it
writes for that change, are not repository reads. Each fetch into the
git repository that the program makes, itself or through any program
that it uses, during a repository read is part of that repository read,
such as a fetch of git objects that a partial clone leaves out and that
the repository read uses; no push, and no other change of a ref, is part
of one. A repository read lasts from the first time that the program,
itself or through any program that it uses, takes bytes, or uses a
pathname to reach a repository file or to look for one, for that
repository read, until the last time that it does one of these. What the
program does after that time, such as giving what it took, is not part
of the repository read; a program still gives a thing in a repository
read when it gives what that repository read took, whenever it gives it.

### 4.28 Undisturbed repository reads

@term undisturbed-read=v1
@cites {
    posix/2024,
    gitdoc/gitrepository-layout,
    gitdoc/git-fetch,
    gitdoc/gitformat-loose,
    gitdoc/gitformat-pack,
    gitdoc/gitformat-commit-graph,
    gitdoc/gitformat-index,
    files#{
        taken-byte=v1, regular-file=v1, folder=v1, folder-tree=v1,
        symbolic-link=v1, file-of-another-kind=v1,
    },
    text#{code-span=v1},
    #{
        repository-read=v1, working-tree=v1, repository-file=v1, commit=v1,
        working-tree-file=v1, git-folder=v1, ref-commit=v1,
        remote-transfer=v1,
    },
}

A repository read is undisturbed when no process, the program that makes
it included, does one of these during the repository read, other than in
an own change of the repository read when the file of that own change
is not a file of a working tree of the git repository, as the term
`working-tree` gives these files:

1. It creates, deletes, or changes a repository file of the git
   repository, when the program, itself or through any program that it
   uses, takes bytes from that file in the repository read.
2. It changes which file a pathname names, or whether it names one, when
   the program, itself or through any program that it uses, uses that
   pathname in the repository read to reach a repository file of the git
   repository or to look for one.

To change a file is to change the content of a regular file, the folder
entries of a folder, the reference of a symbolic link, or the data of a
file of another kind.

An own change of a repository read is the creation, the deletion, or
the change of one file that the program that makes the repository read,
itself or through any program that it uses, makes during the repository
read, when that file is one of these:

1. in an object database of the git repository, a file of a loose
   object or of a pack that the program creates in the repository read,
   as the pages gitformat-loose and gitformat-pack define loose objects
   and packs; a file that is for such a pack alone, such as its pack
   index; or a folder of the folder tree of that object database;
2. in a fetch that is part of the repository read, a commit-graph file
   of an object database of the git repository, as the page
   gitformat-commit-graph gives them: the file `info/commit-graph` of
   that object database, the folder `info/commit-graphs` of it, or a
   file in that folder;
3. git's index of a working tree, a file that the format of that index
   names, as the page gitformat-index gives that format, or the folder
   that holds that index, when git's index holds an entry for the same
   byte paths after the change as before it, as the term
   `working-tree-file` gives these words;
4. a lock file or a temporary file that the program creates in a folder
   of item 1, 2, or 3, and that it deletes, or renames to a file of item
   1, 2, or 3.

A change of a folder of item 1, 2, or 3 is an own change only when each
folder entry that the change creates, deletes, or changes names, before
or after the change, a file of item 1, 2, 3, or 4 that is not a folder,
or a folder that the program created in the repository read. A file
that holds a ref, the file `FETCH_HEAD` or the file `shallow` of the git
folder, and the file `info/alternates` of an object database give no own
change, not even as a file of item 4 that the program creates and then
deletes in the repository read. No other file gives an own change.

### 4.29 Repository files

@term repository-file=v1
@cites {
    gitdoc/gitrepository-layout,
    gitdoc/gitattributes,
    posix/2024,
    files#{folder-tree=v1, folder=v1, symbolic-link=v1},
    text#{code-span=v1},
    #{
        git-folder=v1, working-tree=v1, git-configuration=v1,
        ignored-path=v1, commit=v1,
    },
}

The repository files of a git repository are the files of the folder
trees whose roots are its git folder, each of its object databases, and
the root folder of each working tree of it; the files to which the
symbolic links of the folder tree of the git folder, and of the folder
trees of its object databases, lead, and the files of the folder tree
whose root is each such file that is a folder, in turn; the files of the
git configuration of the git repository and of each working tree of it;
the excludes file of each working tree of it; git's index of each
working tree of it, with the files that the format of that index names;
and the files of git attributes that the page gitattributes gives for
the git repository and for each working tree of it other than as files
`.gitattributes` in the folders of its working trees, with the symbolic
links on their pathnames followed.

### 4.30 Values from a git repository

@term repository-value=v1
@cites {
    gitdoc/git-config,
    text#{code-span=v1},
    #{git-folder=v1, working-tree=v1, git-configuration=v1},
}

A value of a setting of a git configuration comes from a git repository
when the file `config` of the git folder of that git repository, a file
`config.worktree` in the folder of a working tree of it, or a file that
one of these files includes, in turn, by the includes that the page
git-config gives, holds that value.

### 4.31 Fetches and pushes

@term remote-transfer=v1
@cites {
    gitdoc/git-config,
    gitdoc/git-fetch,
    gitdoc/git-push,
    text#{code-span=v1},
    #{git-configuration=v1, ref-commit=v1},
}

A remote of a git repository is a name r for which the git configuration
of the git repository gives a value of the setting `remote.<name>.url`
with r for `<name>`. The addresses of the remote r for a fetch and for a
push are those that the page git-config gives for them by the settings
`remote.<name>.url` and `remote.<name>.pushurl`, with r for `<name>`,
after the rewrite that it gives by the settings `url.<base>.insteadOf`
and `url.<base>.pushInsteadOf`. A fetch from a remote is a transfer of
git objects, refs, or both into the git repository from the git
repository at an address of the remote for a fetch, as the page
git-fetch defines fetches. A push to a remote is a transfer of git
objects, refs, or both from the git repository into the git repository
at an address of the remote for a push, as the page git-push defines
pushes.

### 4.32 Program files

@term program-file=v1
@cites {files#{system=v1}, text#{conforming-program=v1}}

The program files of a conforming program are the files that the system
loads to start it, such as its executable file and its libraries, and
the files that the act that installed the conforming program put on the
system, as that act put them, with the files of the other programs and
libraries that the same act put there, such as its modules, its data,
and the modules of its libraries. A file that the program or its runtime
creates as it runs, such as a cache of compiled code, is not a program
file.

## 5. Requirements

### 5.1 The validation of branch names

@req validate-branch-names=v1
@cites {
    #{branch-name=v1},
    text#{conforming-program=v1, result=v1, text=v1},
}

When a conforming program gives a result for whether a text is a branch
name, it must give exactly one result: "valid" when the text is a branch
name, and "invalid" when the text is not a branch name.

### 5.2 Reach

@req decide-reach=v1
@cites {
    #{commit=v1, ancestry=v1, repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1, result=v1},
}

When, in an undisturbed repository read, a conforming program gives a
result for whether a commit c of a git repository reaches a commit c′ of
it, it must give exactly one result: "reaches" when c reaches c′, and
"does not reach" when c does not reach c′.

### 5.3 Parents

@req give-commit-parents=v1
@cites {
    #{commit=v1, repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1},
}

When it gives the parents of a commit of a git repository, in an
undisturbed repository read, a conforming program must give exactly the
parents of that commit, in their order.

### 5.4 The texts of messages

@req give-message-texts=v1
@cites {
    #{
        commit=v1, message-text=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    text#{conforming-program=v1, text=v1},
}

When it gives the text of the message of a commit of a git repository,
or gives that the message of that commit has no text, in an undisturbed
repository read, a conforming program must give the text of the message
of that commit when it has a text, and give that it has no text when it
has none.

### 5.5 The commits of refs

@req give-ref-commits=v1
@cites {
    #{ref-commit=v1, repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1},
}

When it gives the commit of a ref of a git repository, or gives that the
ref has no commit, in an undisturbed repository read, a conforming
program must give the commit of that ref when the ref has one, and give
that it has none when it has none.

### 5.6 The commit of the default branch

@req give-default-branch-commits=v1
@cites {
    #{
        commit=v1, git-configuration=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1},
    ontology#{default-branch=v1, parameter=v1},
    text#{conforming-program=v1, code-span=v1},
}

When it gives the commit of the default branch of a git repository under
a binding of `default-branch-name`, or gives that the default branch has
no commit under that binding, in an undisturbed repository read, a
conforming program must give the commit of the default branch under that
binding when it has one, and give that it has none when it has
none.

### 5.7 Head commits

@req give-head-commits=v1
@cites {
    #{
        commit=v1, working-tree=v1, head-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    text#{conforming-program=v1},
}

When it gives the head commit of a working tree of a git repository, or
gives that the working tree has no head commit, in an undisturbed
repository read, a conforming program must give the head commit of that
working tree when it has one, and give that it has none when it has
none.

### 5.8 The files of the tree of a commit

@req give-commit-files=v1
@cites {
    #{
        commit=v1, commit-file=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When it gives the valid paths of the files of the tree of a commit of a
git repository, or those files, in an undisturbed repository read, a
conforming program must give exactly the valid paths of the files of the
tree of that commit, and, as the content of each file whose content it
gives, exactly the content of that file.

### 5.9 A file of the tree of a commit

@req give-commit-file-at-path=v1
@cites {
    #{
        commit=v1, commit-file=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When, in an undisturbed repository read, it gives the file with a valid
path p of the tree of a commit of a git repository, or gives that the
tree of that commit has no file with the valid path p, a conforming
program must give that file, with exactly its content, when that tree
has a file with the valid path p, and give that the tree has no file
with the valid path p when it has none.

### 5.10 The files of the tree of a working tree

@req give-working-tree-files=v1
@cites {
    #{
        working-tree=v1, working-tree-file=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When it gives the valid paths of the files of the tree of a working tree
of a git repository, or those files, in an undisturbed repository read,
a conforming program must give exactly the valid paths of the files of
the tree of that working tree, and, as the content of each file whose
content it gives, exactly the content of that file.

### 5.11 A file of the tree of a working tree

@req give-working-tree-file-at-path=v1
@cites {
    #{
        working-tree=v1, working-tree-file=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When, in an undisturbed repository read, it gives the file with a valid
path p of the tree of a working tree of a git repository, or gives that
the tree of that working tree has no file with the valid path p, a
conforming program must give that file, with exactly its content, when
that tree has a file with the valid path p, and give that the tree has
no file with the valid path p when it has none.

### 5.12 Ranges

@req give-ranges=v1
@cites {
    #{
        commit=v1, commit-range=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    text#{conforming-program=v1},
}

When it gives the commits of the range from a commit, or from no commit,
to a commit of a git repository, in an undisturbed repository read, a
conforming program must give exactly the commits of that range.

### 5.13 Parents-first orders

@req give-parents-first-orders=v1
@cites {
    #{
        commit=v1, commit-range=v1, parents-first-order=v1,
        repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1},
}

When it gives the commits of a range of a git repository, in an
undisturbed repository read, in an order that it gives as their
parents-first order, a conforming program must give them in the
parents-first order of that range.

### 5.14 The change of a commit

@req give-changes-of-commits=v1
@cites {
    #{
        commit=v1, git-configuration=v1, change-of-a-commit=v1,
        default-branch-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ontology#{default-branch=v1, parameter=v1},
    text#{conforming-program=v1, code-span=v1},
}

When it gives the commits of the change of a commit h of a git
repository under a binding of `default-branch-name`, or gives that h has
no change under that binding, in an undisturbed repository read, a
conforming program must give exactly the commits of the change of h when
the default branch has a commit under that binding, and give that h has
no change when the default branch has no commit under that
binding.

### 5.15 Merge bases

@req give-merge-bases=v1
@cites {
    #{
        commit=v1, merge-base=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    text#{conforming-program=v1},
}

When it gives the merge bases of two commits of a git repository, in an
undisturbed repository read, a conforming program must give exactly the
merge bases of those two commits.

### 5.16 The base of the change of a commit

@req give-change-bases=v1
@cites {
    #{
        commit=v1, git-configuration=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1},
    ontology#{parameter=v1},
    text#{conforming-program=v1, code-span=v1},
}

When it gives the base of the change of a commit h of a git repository
under a binding of `default-branch-name`, or gives that the change of h
has no base under that binding, in an undisturbed repository read, a
conforming program must give the base of the change of h under that
binding when it has one, and give that it has none when it has
none.

### 5.17 First-parent lines

@req give-first-parent-lines=v1
@cites {
    #{
        commit=v1, first-parent-line=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    text#{conforming-program=v1},
}

When it gives the first-parent line of a commit of a git repository, in
an undisturbed repository read, a conforming program must give exactly
the commits of that first-parent line, in the order of that first-parent
line.

### 5.18 Landing commits

@req give-landing-commits=v1
@cites {
    #{
        commit=v1, ancestry=v1, first-parent-line=v1, landing-commit=v1,
        repository-read=v1, undisturbed-read=v1},
    text#{conforming-program=v1},
}

When it gives the landing commit of a commit c on the first-parent line
of a commit d of a git repository, or gives that c has no landing commit
on that first-parent line, in an undisturbed repository read, a
conforming program must give the landing commit of c on that
first-parent line when c has one, and give that c has none when d does
not reach c.

### 5.19 Hunks

@req give-hunks=v1
@cites {
    #{
        line-map=v1, hunk=v1, repository-read=v1, working-tree=v1,
        git-configuration=v1, ignored-path=v1, commit=v1,
        commit-file=v1, working-tree-file=v1, undisturbed-read=v1},
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When it gives the hunks of a valid path p between an old tree and a new
tree, a conforming program must give exactly the hunks of p between
those trees for one line map of p between those trees, each with its old
start, the number of the lines that it removes, its new start, and the
number of the lines that it adds, and, when it gives the lines that a
hunk removes or adds, exactly those lines. When one of the two trees is
the tree of a commit or of a working tree of a git repository, this
obligation holds only in an undisturbed repository read.

### 5.20 The line numbers of lines that stay

@req give-new-line-numbers=v1
@cites {
    #{
        line-map=v1, repository-read=v1, working-tree=v1,
        git-configuration=v1, ignored-path=v1, new-line-number=v1,
        commit=v1, commit-file=v1, working-tree-file=v1,
        undisturbed-read=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{
        conforming-program=v1, line=v1, line-number=v1, whole-number=v1,
        text-of-a-byte-sequence=v1,
    },
}

When it gives new line numbers of old lines of a valid path p between an
old tree and a new tree, a conforming program must give them for one
line map M of p between those trees: for each old line i of p for which
it gives a new line number, or gives that the line has none, it must
give the new line number of i for M when i has one, and give that i has
none when i has no new line number for M. When one of the two trees is
the tree of a commit or of a working tree of a git repository, this
obligation holds only in an undisturbed repository read.

### 5.21 One line map for hunks and line numbers

@req use-one-line-map=v1
@cites {
    #{line-map=v1, hunk=v1, new-line-number=v1},
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When, in one execution of the program, a conforming program gives hunks
of a valid path
p between an old tree and a new tree, new line numbers of old lines of p
between those trees, or both, it must give all of them for one line map
of p between those trees.

### 5.22 The diff of the change of a commit

@req give-change-diffs=v1
@cites {
    #{
        git-configuration=v1, change-of-a-commit=v1, change-diff=v1,
        line-map=v1, hunk=v1, repository-read=v1, change-base=v1,
        undisturbed-read=v1,
    },
    ontology#{parameter=v1},
    files#{path=v1},
    text#{conforming-program=v1, code-span=v1},
}

When it gives a diff of the change of a commit h of a git repository
under a binding of `default-branch-name`, or gives that the change of h
has no diff under that binding, in an undisturbed repository read, a
conforming program must give a diff of the change of h under that
binding when the change of h has a base, and give that it has no diff
when the change of h has no base under that binding.

### 5.23 No change to the repository by a read

@req leave-repositories-unchanged=v1
@cites {
    posix/2024,
    #{repository-read=v1, repository-file=v1, undisturbed-read=v1},
    text#{conforming-program=v1},
}

During each repository read, a conforming program, itself or through any
program that it uses, must create, delete, or change no repository file
of the git repository, as the term `undisturbed-read` gives these words,
other than in an own change of that repository read, as that term gives
these words, and other than in a change of a file that was open in the
process of the program when that process started, such as its standard
output.

### 5.24 Bytes only from the repository and the fetches of the read

@req read-only-repository-files=v1
@cites {
    posix/2024,
    #{
        repository-file=v1, repository-read=v1, program-file=v1,
        remote-transfer=v1,
    },
    files#{system=v1, symbolic-link=v1, taken-byte=v1},
    text#{conforming-program=v1},
}

In each repository read, a conforming program, itself or through any
program that it uses, must take bytes only from these:

1. the repository files of the git repository, and the symbolic links on
   the pathnames by which it reaches them;
2. a pipe between it and a program that it uses, and a file or a pipe
   that was open in the process of the program when that process
   started, such as its standard input;
3. a file that it created in that execution;
4. a program file of the conforming program;
5. in a fetch from a remote, when that fetch is part of the repository
   read, the git repository at an address of that remote for a fetch,
   and the connections through which that fetch reaches it;
6. a file that the system or the libraries of a program read to run that
   program, and, in a fetch that is part of the repository read, a file
   that a program that makes that fetch reads as it is set up, such as
   the configuration and the keys of an SSH client or the store of a
   credential helper.

### 5.25 No permission or privilege that the process did not have

@req gain-no-repository-privileges=v1
@cites {
    posix/2024,
    #{repository-read=v1},
    files#{system=v1},
    text#{conforming-program=v1},
}

In each repository read, a conforming program must use only the
permissions and the appropriate privileges, as POSIX.1-2024 defines
these, such as a capability on a system that gives capabilities to
processes, that its process has when the program does not change them:
not one that it gets by changing the user IDs, the group IDs, or the
appropriate privileges of its process, or through another process that
acts for it.

### 5.26 No program or command that a git repository supplies

@req run-no-configured-programs=v1
@cites {
    posix/2024,
    gitdoc/githooks,
    gitdoc/git-config,
    gitdoc/git-fetch,
    gitdoc/git-remote-ext,
    #{
        git-configuration=v1, git-folder=v1, working-tree=v1,
        repository-read=v1, repository-value=v1, remote-transfer=v1,
        program-file=v1,
    },
    files#{system=v1, folder-tree=v1, symbolic-link=v1},
    text#{conforming-program=v1, code-span=v1},
}

In each execution in which a conforming program makes a repository read,
a fetch, or a push, it must, itself or through any program that it uses,
run none of these, for each git repository that it, itself or through
any program that it uses, reads, fetches into or from, or pushes from or
to in that execution (these git repositories): a hook that the page
githooks defines; a program that is a file of the folder tree of the git
folder of the git repository or a file of a working tree of it, or that
it reaches through a symbolic link that is such a file (a file of these
git repositories), other than a program file of the conforming program,
where a program that another act of installing put on the system, such
as `git` or `ssh` installed on their own, is not one; and a program or
command that the git configuration of the git repository or of a working
tree of it names, gives, or causes to run, such as a filter, the command
of the setting `core.fsmonitor`, or the command of an address
`ext::<command>`. In a fetch into a git repository from a remote of it,
or in a push from a git repository to a remote of it, it may still run
the programs that make that fetch or push as they are set up outside
these git repositories, such as `ssh` or a credential helper, other than
a program that is a file of these git repositories; a value of a setting
that does not come from a git repository is set up outside them. In such
a fetch or push, it still runs no hook, and no program or command that a
value from a git repository names or gives, other than the program that
the form of an address chooses for the transfer and the command that the
form of that address gives to the git repository at that address, such
as `ssh` or a remote helper and `git-upload-pack` with the path of the
address: for example, not the command of the setting `core.sshCommand`
in the file `config` of the git folder, and not the command of an
address `ext::<command>`. To run a program is to start a process from a
file on the system of the program, or to load a file as code that runs
in the process of the program; to run a command is to have a shell or
another program carry it out; and to give a program or a command to run
to another computer, or to a server that an address reaches, as through
`ssh` or at an address that is a local path or a `file://` URL, as the
page git-fetch gives these forms, counts as running it. What such a
server then runs by its own setup, on any computer, such as a hook of
the git repository there, does not count as a program or a command that
the conforming program runs, other than what a server at an address
that is a local path or a `file://` URL, as the page git-fetch gives
these forms, runs in a fetch that is part of a repository read. Code
that runs isolated from the rest of the process of the program, as
WebAssembly code runs in a sandbox, is not a program that runs in this
sense.

### 5.27 No symbolic link followed in a working tree

@req follow-no-working-tree-links=v1
@cites {
    gitdoc/gitattributes,
    #{
        git-folder=v1, working-tree=v1, git-configuration=v1,
        ignored-path=v1, repository-read=v1, program-file=v1,
        remote-transfer=v1,
    },
    files#{symbolic-link=v1, folder=v1},
    text#{conforming-program=v1, code-span=v1},
}

In each repository read, a conforming program, itself or through any
program that it uses, must follow no symbolic link that is a file of a
working tree of the git repository, other than a symbolic link on the
way to a file of the git configuration of the git repository or of a
working tree of it, to the file `info/exclude` of the git folder, to the
excludes file of a working tree of it, to a file of git attributes that
the page gitattributes gives for the git repository or for a working
tree of it other than as a file `.gitattributes` in a folder of a
working tree, to a program file of the conforming program, or, in a
fetch that is part of the repository read, to a file that a program that
makes that fetch reads as it is set up: it must find no file by the
reference of such a symbolic link.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`changes.test-vectors.jsonl`](changes.test-vectors.jsonl), in the same
folder as this design. The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1), in the format
that the specification
[`data-forms#test-vectors`](sinter:data-forms#test-vectors=v1) gives. A
program does not need the revisions to run the vectors. A vector is an
input and what a conforming program gives for it. Each vector follows
from the requirements and adds nothing to them. The vectors are in
groups. Each group has a name, such as `hunks`, and a subsection below.
The subsection names the requirements that the vectors of the group
follow from, and it describes their inputs, results, and values. Each
vector of a group follows from one or more of these requirements. No
vector follows from the requirements `use-one-line-map`,
`leave-repositories-unchanged`, `read-only-repository-files`,
`gain-no-repository-privileges`, `run-no-configured-programs`, and
`follow-no-working-tree-links`.

Each requirement from which vectors follow applies only when a program
gives the thing that it names, such as the base of the change of a
commit. So a vector holds a
program only to what the program gives for the input. The subsection of
each group says what a conforming program gives in each case. When a
subsection says that a conforming program gives a thing, such as the
landing commit of `landing-commits`, it gives that thing and no other
thing of the same kind, such as no other landing commit for the same two
commits.

The input of a vector stands for a text, a git repository, a working
tree, or two trees, in the forms that the subsection of its group gives.
A vector names each commit by a short name, such as `a`, which stands
for that commit. The git repository of a vector holds the commits that
its input names, and, for a vector of the groups `commit-files`,
`message-texts`, and `parents`, the commit that its input stands for,
and no other commit. Each vector whose input stands for a git repository or a working
tree stands for an undisturbed repository read.

The subsections name JSON objects, members, arrays, strings, numbers,
and the literal names `true` and `false` as RFC 8259 defines them.
Inside the members `input`, `result`, and `values`, each JSON value that
the subsection of a group names as a text, a byte sequence, a whole
number, a commit, a commit graph, a tree, a folder tree, a sequence, a
set of commits, a set of texts, or a list of texts has this form:

- A text, such as a result, a branch name, a ref name, or a valid path,
  is a JSON string whose characters are the characters of the text, in
  order.
- A byte sequence, such as a content or the name of an entry, is a JSON
  string when it is the UTF-8 encoding of a text: the JSON string of
  that text. Otherwise, it is a JSON object with one member, `bytes`,
  whose value is a JSON string of hex digits: for each byte, in order,
  the hex digit of the whole-number quotient of the byte divided by 16,
  then the hex digit of the remainder, each in lower case. So the
  content `a`, then a line feed, is `"a\n"`, and the byte sequence
  0xFF is `{"bytes":"ff"}`.
- A whole number, such as a line number, is a JSON number written as its
  decimal numeral, such as `12`.
- A commit is a JSON string: the name of the commit in the vector. A git
  object that is not a commit is a JSON string in the same way: its name
  in the vector.
- A commit graph is a JSON object with one member for each commit of the
  git repository of the vector. The key of the member is the name of the
  commit, and its value is a JSON array of the names of the parents of
  the commit, in their order. So `{"a":[],"b":["a"]}` is a commit `a`
  with no parents and a commit `b` whose first parent is `a`. A commit
  with no parents in a commit graph can also stand for a commit that the
  file `shallow` names.
- A tree is a JSON object with one member for each file of the tree. The
  key of the member is the valid path of the file, and its value is the
  content of the file, as a byte sequence.
- A folder tree is a
  [folder tree object](sinter:files#folder-tree-object=v1), whose file
  objects are [file objects](sinter:files#file-object=v1).
- A sequence, such as the commits of a first-parent line, is a JSON
  array of its elements, in order.
- A set of commits, such as the merge bases of two commits, is a JSON
  array of the names of its commits, each once, in
  [code point order](sinter:text#code-point-order=v1) of the names.
- A set of texts, such as the valid paths of the files of a tree, is a
  JSON array of its elements, each
  once, in [code point order](sinter:text#code-point-order=v1).
- A list of texts, such as the values of a setting, is a JSON array of
  its texts, in their order.

### 6.1 Branch names

The group `branch-names` holds the vectors of the requirement
`validate-branch-names`. Each vector gives a text and whether it is a
branch name.

- `input`: the text.
- `result`: "valid" when the text is a branch name, and "invalid" when
  it is not.
- `values`: no vector of the group has this member.

When a conforming program gives a result for whether the text is a
branch name, it gives the result that `result` holds, and no other
result.

```
{"group":"branch-names","input":"HEAD","n":9,"note":"a branch name is not `HEAD`","result":"invalid","rev":"v1"}
```

### 6.2 The commit of the default branch

The group `default-branch-commits` holds the vectors of the requirement
`give-default-branch-commits`. Each vector gives a binding of
`default-branch-name`, the refs that exist, and the commit of the
default branch.

- `input`: a JSON object. Its member `binding` is the binding of
  `default-branch-name`, a text b. Each of its members `upstream`,
  `local`, and `remote` is there when, and only when, its ref exists in
  the git repository, and its value is the commit of that ref, or the
  empty JSON object, `{}`, when that ref has no commit: `upstream` for
  the upstream of the branch b, which item 1 of the term
  `default-branch-commit` gives; `local` for the ref whose name is
  `refs/heads/` followed by b; and `remote` for the ref whose name is
  `refs/remotes/origin/` followed by b. No ref of the three exists other
  than those that the members name.
- `result`: no vector of the group has this member.
- `values`: when the default branch has a commit, a JSON object with one
  member, `commit`: that commit. When it has none, the empty JSON
  object, `{}`.

When a conforming program gives the commit of the default branch under
the binding, or gives that the default branch has no commit under it, it
gives the commit that `commit` holds when `values` has that member, and
it gives that the default branch has no commit when `values` is
`{}`.

```
{"group":"default-branch-commits","input":{"binding":"main","local":"l","remote":"r","upstream":"u"},"n":41,"note":"the upstream comes first","rev":"v1","values":{"commit":"u"}}
{"group":"default-branch-commits","input":{"binding":"main"},"n":46,"note":"none of the three refs exists","rev":"v1","values":{}}
```

### 6.3 Head commits

The group `head-commits` holds the vectors of the requirement
`give-head-commits`. Each vector gives the HEAD of a working tree, the
refs of the git repository, and the head commit of the working tree.

- `input`: a JSON object with two members. `head` is a JSON object with
  one member: `ref`, the name of the ref that HEAD names, a text; or
  `commit`, the commit to which a detached HEAD points. `refs` is a JSON
  object with one member for each ref of the git repository: its key is
  the name of the ref, a text, and its value is the commit to which the
  ref points.
- `result`: no vector of the group has this member.
- `values`: when the working tree has a head commit, a JSON object with
  one member, `commit`: that commit. When it has none, the empty JSON
  object, `{}`.

When a conforming program gives the head commit of the working tree, or
gives that the working tree has none, it gives the commit that `commit`
holds when `values` has that member, and it gives that the working tree
has no head commit when `values` is `{}`.

```
{"group":"head-commits","input":{"head":{"ref":"refs/remotes/origin/main"},"refs":{"refs/remotes/origin/main":"e"}},"n":137,"note":"HEAD can name a ref that is not a branch","rev":"v1","values":{"commit":"e"}}
```

### 6.4 The files of the tree of a commit

The group `commit-files` holds the vectors of the requirements
`give-commit-files` and `give-commit-file-at-path`. Each vector gives
the git tree object of a commit and the valid paths of the files of the
tree of the commit.

- `input`: a JSON object with one member, `entries`: a JSON array with
  one JSON object for each entry that the git tree object of the commit
  lists, in the order in which it lists them. The JSON object of an
  entry has the member `name`, the name of the entry, a byte sequence,
  and the member `mode`, the mode of the entry, a text of octal digits,
  such as `100644`, or `40000`, which the page gitdatamodel writes as
  `040000`. The JSON object of a tree entry also has the member
  `entries`, in the same form, for the entries that the git tree object
  that it names lists. A regular-file entry and a symbolic-link entry
  name blobs, and a submodule entry names a commit of another git
  repository; the vectors do not give their contents.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `paths`: the set of the valid
  paths of the files of the tree of the commit.

When a conforming program gives the valid paths of the files of the tree
of the commit, or those files, it gives one valid path, or one file with
that valid path, for each element of `paths`, and no other. When it
gives the file with a valid path, or gives that there is none, it gives
the file when `paths` holds that valid path, and that there is none when
`paths` does not. The content of each file is the content of the blob of
its entry, which the vectors do not give.

```
{"group":"commit-files","input":{"entries":[{"mode":"100664","name":"old.md"}]},"n":87,"note":"an old mode of a regular file","rev":"v1","values":{"paths":["old.md"]}}
```

### 6.5 The files of the tree of a working tree

The group `working-tree-files` holds the vectors of the requirements
`give-working-tree-files` and `give-working-tree-file-at-path`. Each
vector gives the folder tree of a working tree, the paths that git's
index holds, the paths that are ignored, and the valid paths of the
files of the tree of the working tree.

- `input`: a JSON object with three members. `folder-tree` is the folder
  tree whose root is the root folder of the working tree, as a folder
  tree. In it, each folder whose entry name is `.git` holds no folder
  entry, and a regular file whose entry name is `.git` has an empty
  content: the vector leaves out the files inside such a folder, such as
  the files of the git folder, and the content of such a regular file,
  which names a git folder. A check of the vectors gives these files and
  this content as the git repository of the working tree needs them. The
  members `tracked` and `ignored` give the facts of the left-out files
  on which the result depends. `tracked` is the set of the valid paths p
  such that git's index of the working tree holds an entry for the UTF-8
  encoding of p, as a set of texts. `ignored` is the set of the valid
  paths of the regular files of the folder tree that are ignored in the
  working tree, as a set of texts. It can hold a path that `tracked`
  also holds. The input stands for a repository read of the working tree
  during which a file system stores the folder tree of `folder-tree`, as
  a [stored folder tree](sinter:files#stored-folder-tree=v1), for the
  process of the program, apart from the files and the contents that the
  vector leaves out. When the root folder of `folder-tree` holds no
  folder entry `.git`, the git folder of the working tree is outside the
  folder tree.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `paths`: the set of the valid
  paths of the files of the tree of the working tree.

When a conforming program gives the valid paths of the files of the tree
of the working tree, or those files, it gives one valid path, or one
file with that valid path, for each element of `paths`, and no other.
When it gives the file with a valid path, or gives that there is none,
it gives the file when `paths` holds that valid path, and that there is
none when `paths` does not. The content of each file is the content of
its regular file.

These are the need names of this design, what each need is, and when a
vector has it.

- `names-kept`: the folder tree is on a file system that keeps each
  entry name of the folder tree as the check of the vectors makes it,
  byte for byte, such as a file system that does not change an entry
  name into a decomposed form of Unicode normalization, and the git
  configuration of the working tree does not give the setting
  `core.precomposeUnicode` the value true. A vector has
  this need when an entry name of its folder tree is valid UTF-8 and
  holds a byte of 0x80 or more.
- `non-utf-8-names`: the folder tree is on a file system that keeps each
  entry name of the folder tree that is not valid UTF-8 as the check of
  the vectors makes it, byte for byte. A vector has this need when an
  entry name of its folder tree is not valid UTF-8.

```
{"group":"working-tree-files","input":{"folder-tree":{"entries":[{"file":{"entries":[{"file":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"73746f7265"}],"type":"directory"},"name":"7265706f"}],"type":"directory"},"name":"2e6a6a"},{"file":{"content":[],"type":"regular file"},"name":"612e6d64"}],"type":"directory"},"ignored":[],"tracked":["a.md"]},"n":101,"note":"a colocated jj repository","rev":"v1","values":{"paths":["a.md"]}}
{"group":"working-tree-files","input":{"folder-tree":{"entries":[{"file":{"content":[],"type":"regular file"},"name":"636166e92e6d64"},{"file":{"content":[],"type":"regular file"},"name":"6f6b2e6d64"}],"type":"directory"},"ignored":[],"tracked":["ok.md"]},"n":105,"needs":["non-utf-8-names"],"note":"a name that is not valid UTF-8","rev":"v1","values":{"paths":["ok.md"]}}
```

### 6.6 Reach

The group `reach` holds the vectors of the requirement `decide-reach`.
Each vector gives a commit graph, two commits c and c′, and whether c
reaches c′.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `commit` is the commit c, and its member `other` is the commit
  c′.
- `result`: "reaches" when c reaches c′, and "does not reach" when it
  does not.
- `values`: no vector of the group has this member.

When a conforming program gives a result for whether c reaches c′, it
gives the result that `result` holds, and no other result.

```
{"group":"reach","input":{"commit":"g","commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"other":"d"},"n":154,"note":"through the second parent of `f`","result":"reaches","rev":"v1"}
```

### 6.7 Parents

The group `parents` holds the vectors of the requirement
`give-commit-parents`. Each vector gives what a commit object names as
its parents, whether the file `shallow` names the commit, and the
parents of the commit.

- `input`: a JSON object. Its member `named` is the commits that the
  commit object names as its parents, as a sequence. Its member
  `shallow` is the JSON literal name `true` when the file `shallow`
  names the commit, and `false` when it does not.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `parents`: the parents of the
  commit, as a sequence.

When a conforming program gives the parents of the commit, it gives the
elements of `parents`, in their order, and no other commit.

```
{"group":"parents","input":{"named":["a"],"shallow":true},"n":163,"note":"the file `shallow` names the commit","rev":"v1","values":{"parents":[]}}
```

### 6.8 The commits of refs

The group `ref-commits` holds the vectors of the requirement
`give-ref-commits`. Each vector gives the refs of a git repository, one
ref, and the commit of that ref.

- `input`: a JSON object with two members. `ref` is the name of the ref,
  a text. `refs` is a JSON object with one member for each ref that
  exists in the git repository: its key is the name of the ref, and its
  value is a JSON object with one member: `commit`, the commit to which
  the ref points; `ref`, the name of the ref that it names, for a
  symbolic ref; or `other`, the name of a git object that is not a
  commit, to which the ref points.
- `result`: no vector of the group has this member.
- `values`: when the ref has a commit, a JSON object with one member,
  `commit`: that commit. When it has none, the empty JSON object, `{}`.

When a conforming program gives the commit of the ref, or gives that the
ref has none, it gives the commit that `commit` holds when `values` has
that member, and it gives that the ref has no commit when `values` is
`{}`.

```
{"group":"ref-commits","input":{"ref":"refs/heads/dangling","refs":{"refs/heads/alias":{"ref":"refs/heads/main"},"refs/heads/alias2":{"ref":"refs/heads/alias"},"refs/heads/dangling":{"ref":"refs/heads/gone"},"refs/heads/main":{"commit":"c"},"refs/tags/v1":{"other":"t"}}},"n":169,"note":"a symbolic ref that names a ref that does not exist","rev":"v1","values":{}}
```

### 6.9 Ranges

The group `ranges` holds the vectors of the requirements `give-ranges`
and `give-parents-first-orders`. Each vector gives a commit graph, two
commits or one, and the commits of a range in their parents-first
order.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `to` is the commit h, and its member `from` is the commit s.
  The range is the range from s to h, or, when the object has no member
  `from`, the range from no commit to h.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `order`: the commits of the
  range, as a sequence in their parents-first order.

When a conforming program gives the commits of the range, it gives each
element of `order`, and no other commit. When it gives them in an order
as their parents-first order, it gives them in the order of `order`.

```
{"group":"ranges","input":{"commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"from":"b","to":"g"},"n":51,"note":"the walk from `g` takes the first parent `c` of `f` before its second parent `e`","rev":"v1","values":{"order":["c","d","e","f","g"]}}
```

### 6.10 The change of a commit and its base

The group `changes` holds the vectors of the requirements
`give-changes-of-commits`, `give-merge-bases`, and
`give-change-bases`. Each vector
gives a commit graph, the commit of the default branch, and a commit h;
the commits of the change of h; the merge bases of h and the commit of
the default branch; and the base of the change of h, when it has one.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `last` is the commit h, and its member `default` is the commit
  of the default branch, under a binding of `default-branch-name` under
  which the default branch has that commit.
- `result`: no vector of the group has this member.
- `values`: a JSON object. Its member `change` is the set of the commits
  of the change of h, as a set of commits. Its member `merge-bases` is
  the set of the merge bases of h and the commit of the default branch,
  as a set of commits. Its member `base` is there when, and only when,
  the change of h has a base, and then it is that base.

When a conforming program gives the commits of the change of h, it
gives each element of `change`, and no other commit. When it gives the
merge bases of the two commits, it gives each element of `merge-bases`,
and no other commit. When it gives the base of the change of h, or gives
that the change of h has none, it gives the commit that `base` holds
when `values` has that member, and it gives that the change of h has no
base when `values` has no member `base`.

```
{"group":"changes","input":{"commits":{"a":[],"b":["a"],"c":["a"],"m1":["b","c"],"m2":["c","b"]},"default":"m2","last":"m1"},"n":69,"note":"merges that cross: two merge bases, so no base","rev":"v1","values":{"change":["m1"],"merge-bases":["b","c"]}}
```

### 6.11 First-parent lines and landing commits

The group `landing-commits` holds the vectors of the requirements
`give-first-parent-lines` and `give-landing-commits`. Each vector gives
a commit graph, two commits d and c, the first-parent line of d, and the
landing commit of c on that first-parent line, when there is one.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `line-of` is the commit d, and its member `commit` is the
  commit c.
- `result`: no vector of the group has this member.
- `values`: a JSON object. Its member `first-parent-line` is the
  first-parent line of d, as a sequence. Its member `landing-commit` is
  there when, and only when, d reaches c, and then it is the landing
  commit of c on the first-parent line of d.

When a conforming program gives the first-parent line of d, it gives the
elements of `first-parent-line`, in their order, and no other commit.
When it gives the landing commit of c on the first-parent line of d, or
gives that c has none, it gives the commit that `landing-commit` holds
when `values` has that member, and it gives that c has no landing commit
when `values` has no member `landing-commit`.

```
{"group":"landing-commits","input":{"commit":"d","commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"line-of":"g"},"n":72,"note":"`d` landed on the first-parent line of `g` through the merge commit `f`","rev":"v1","values":{"first-parent-line":["g","f","c","b","a"],"landing-commit":"f"}}
```

### 6.12 The texts of messages

The group `message-texts` holds the vectors of the requirement
`give-message-texts`. Each vector gives the message of a commit, the
value of the header `encoding` of its commit object when it has one, and
the text of the message of that commit, when it has one.

- `input`: a JSON object. Its member `message` is the message of the
  commit, as a byte sequence. Its member `encoding` is there when, and
  only when, the commit object has the header `encoding`, and then it is
  the value of that header, as a text.
- `result`: no vector of the group has this member.
- `values`: when the message has a text, a JSON object with one member,
  `text`: that text. When it has no text, the empty JSON object, `{}`.

When a conforming program gives the text of the message of the commit,
or gives that the message has no text, it gives the text that `text`
holds when `values` has that member, and it gives that the message has
no text when `values` is `{}`.

```
{"group":"message-texts","input":{"encoding":"ISO-8859-1","message":{"bytes":"636166e90a"}},"n":174,"note":"the bytes are not valid UTF-8, whatever the header `encoding`","rev":"v1","values":{}}
```

### 6.13 Hunks and line maps

The group `hunks` holds the vectors of the requirements `give-hunks` and
`give-new-line-numbers`. Each vector gives the content of the file with
the valid path `f` in an old tree and in a new tree, the numbers of the
lines that the hunks of `f` between the two trees remove and add, and,
when `f` has one line map between the two trees, that line map and its
hunks.

- `input`: a JSON object. Its member `old` is the content of the file of
  the old tree whose valid path is `f`, a byte sequence. It is there
  when, and only when, the old tree has such a file. Its member `new` is
  the same for the new tree. The program takes the two trees as they are
  given: neither is the tree of a commit or of a working tree that the
  program reads.
- `result`: no vector of the group has this member.
- `values`: a JSON object. Its member `removed` is the number of the
  lines that the hunks of `f` between the old tree and the new tree, for
  a line map of `f` between them, remove together, and its member
  `added` is the number of the lines that they add together; each line
  map gives the same two numbers. When `f` has exactly one line map
  between the two trees, `values` also has two more members. `hunks` is
  a JSON array of the hunks of `f` between the old tree and the new tree
  for that line map, in increasing order of their old starts. Each hunk
  is a JSON object with four members, each a whole number: `old-start`,
  its old start; `removed`, the number of the lines that it removes;
  `new-start`, its new start; and `added`, the number of the lines that
  it adds. `map` is a JSON array of the pairs of that line map, in
  increasing order of their first numbers. Each pair (i, j) is a JSON
  array of two whole numbers, i and then j. When `f` has more than one
  line map, `values` has no other member.

When a conforming program gives the hunks of `f` between the two trees,
the lines that they remove together are as many as `removed` holds, and
the lines that they add together are as many as `added` holds. When
`values` has the member `hunks`, it gives one hunk for each element of
`hunks`, with its four numbers, and no other hunk. When `values` has the
member `map`, and the program gives the new line number of the old line
i of `f`, or gives that the old line i has none, it gives j for the
element of `map` whose first number is i, and it gives that the old
line i has no new line number when no element of `map` has the first
number i.

```
{"group":"hunks","input":{"new":"one\n2\nthree\nfour\n","old":"one\ntwo\nthree\n"},"n":108,"note":"the example of section 2.7","rev":"v1","values":{"added":2,"hunks":[{"added":1,"new-start":2,"old-start":2,"removed":1},{"added":1,"new-start":4,"old-start":4,"removed":0}],"map":[[1,1],[3,3]],"removed":1}}
{"group":"hunks","input":{"new":"b\na\n","old":"a\nb\n"},"n":115,"note":"two line maps: `a` stays, or `b` stays","rev":"v1","values":{"added":1,"removed":1}}
```

### 6.14 The diffs of the changes of commits

The group `change-diffs` holds the vectors of the requirement
`give-change-diffs`. Each vector gives a commit graph, the tree of each
commit, the commit of the default branch, and a commit h, and the diff
of the change of h, when the change of h has a base. In each vector,
each valid path has exactly one line map between the tree of the base
and the tree of h.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `trees` is a JSON object with one member for each commit of the
  commit graph: its key is the name of the commit, and its value is the
  tree of the commit, as a tree. Its member `last` is the commit h, and
  its member `default` is the commit of the default branch, under a
  binding of `default-branch-name` under which the default branch has
  that commit.
- `result`: no vector of the group has this member.
- `values`: when the change of h has a base, a JSON object with one
  member, `diff`: a JSON array with one JSON object for each valid path
  that has one hunk or more in the diff of the change of h, in
  [code point order](sinter:text#code-point-order=v1) of the valid
  paths. That JSON object has two members: `path`,
  the valid path, and `hunks`, its hunks, in the form of the member
  `hunks` of the group `hunks`. Each other valid path has no hunk in the
  diff. When the change of h has no base, the empty JSON object, `{}`.

When a conforming program gives a diff of the change of h, or gives that
the change of h has no diff, it gives, when `values` has the member
`diff`, for each element of `diff`, one hunk for each element of its
`hunks`, with its four numbers and with the valid path of `path`, and no
other hunk, and it gives that the change of h has no diff when `values`
is `{}`.

```
{"group":"change-diffs","input":{"commits":{"a":[],"b":["a"],"c":["a"],"m1":["b","c"],"m2":["c","b"]},"default":"m2","last":"m1","trees":{"a":{},"b":{"b.md":"b\n"},"c":{"c.md":"c\n"},"m1":{},"m2":{}}},"n":148,"note":"the change has no base, so it has no diff","rev":"v1","values":{}}
```

### 6.15 The upstreams of default branches

The group `upstreams` holds the vectors of the requirement
`give-default-branch-commits`. Each vector gives a binding of
`default-branch-name`, the settings of the git configuration of the git
repository, the refs of the git repository, and the commit of the
default branch.

- `input`: a JSON object. Its member `binding` is the binding of
  `default-branch-name`, a text b, which is a branch name. Its member
  `settings` is a JSON object with one member for each setting of the
  git configuration of the git repository: its key is the name of the
  setting, a text such as `branch.main.remote`, and its value is the
  values of the setting, as a list of texts. Its member `refs` is a JSON
  object with one member for each ref of the git repository: its key is
  the name of the ref, a text, and its value is the commit to which the
  ref points.
- `result`: no vector of the group has this member.
- `values`: when the default branch has a commit, a JSON object with one
  member, `commit`: that commit. When it has none, the empty JSON
  object, `{}`.

When a conforming program gives the commit of the default branch under
the binding, or gives that the default branch has no commit under it, it
gives the commit that `commit` holds when `values` has that member, and
it gives that the default branch has no commit when `values` is
`{}`.

```
{"group":"upstreams","input":{"binding":"main","refs":{"refs/heads/main":"l"},"settings":{"branch.main.merge":["refs/heads/main"],"branch.main.remote":["up"],"remote.up.fetch":["refs/heads/*:refs/remotes/up/*"],"remote.up.url":["/nowhere"]}},"n":219,"note":"an upstream that does not exist is not the first ref that exists","rev":"v1","values":{"commit":"l"}}
```

### 6.16 Ignore files

The group `ignore-files` holds the vectors of the requirements
`give-working-tree-files` and `give-working-tree-file-at-path`. Each
vector gives the content of the file `.gitignore` of the root folder of
a working tree, the file names of the other regular files of that root
folder, and the valid paths of the files of the tree of the working
tree.

- `input`: a JSON object with two members. `gitignore` is the content of
  the file `.gitignore`, as a byte sequence. `names` is the set of the
  file names of the other regular files of the root folder, as a set of
  texts; no element is `.git` or `.gitignore`, each element holds only
  characters whose code points are below 128, no two elements differ
  only in the case of the letters from `A` to `Z`, and no element
  differs only in that way from `.git` or `.gitignore`. The input stands
  for a repository read of a working tree whose root folder holds the
  folder entry `.git` of its git folder, the regular file `.gitignore`
  with that content, an empty regular file for each element of `names`,
  and no other folder entry; git's index of the working tree holds no
  entry; the git configuration of the working tree does not give the
  setting `core.ignoreCase` the value true; and no other source of
  patterns that the term `ignored-path` gives holds a pattern.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `paths`: the set of the valid
  paths of the files of the tree of the working tree.

When a conforming program gives the valid paths of the files of the tree
of the working tree, or those files, it gives one valid path, or one
file with that valid path, for each element of `paths`, and no other.
When it gives the file with a valid path, or gives that there is none,
it gives the file when `paths` holds that valid path, and that there is
none when `paths` does not. The content of each file is the content of
its regular file.

```
{"group":"ignore-files","input":{"gitignore":"b.md\r\n","names":["a.md","b.md"]},"n":220,"note":"a carriage return right before a line feed is in no pattern","rev":"v1","values":{"paths":[".gitignore","a.md"]}}
```
