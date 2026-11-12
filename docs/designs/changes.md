<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Changes
@design changes=v1
@cites text=v1
@cites files=v1
@cites ontology=v1
@cites data-forms=v1
@cites git/2.43.7
@cites posix/2024
@cites rfc/8259
Specifies, for git repositories, the git folder, commits and the commits that they reach, the head commit of a working tree, branch names and the commit of the default branch, ranges of commits and their parents-first order, changes, merge bases and the base of a change, first-parent lines and merge commits, the files of the tree of a commit and of the tree of a working tree, line texts, line maps, and hunks between two trees, and the diff of a change; and requirements for conforming programs that read git repositories and that give commits, branches, changes, trees, and hunks.

Sinter reads git repositories. A git repository holds commits. Each
commit names its parents and a git tree object, which holds files.
Branches point to commits. The default branch is the branch into which
work on the repository merges. A change is a set of commits that is to
merge into the default branch as one unit, such as the commits of a pull
request. Sinter compares two trees, such as the tree of the base of a
change and the tree of the last commit of the change, and finds the
lines that differ between them: the hunks.

From git 2.43.7, the design takes the format of a git repository, as
the documentation and the behavior of git 2.43.7 define it: the git
folder, which is the common folder of the repository, and the folder of
each working tree, which the page gitrepository-layout gives; the object
database and its alternates; commit objects, git tree objects with their
entries and modes, and blobs; the files `shallow` and `info/grafts`;
refs, symbolic refs, branches, remote-tracking branches, the upstream of
a branch, and HEAD; git's index; the configuration that git reads, which
the page git-config gives, with the settings `branch.<name>.remote`,
`branch.<name>.merge`, `remote.<name>.fetch`, `core.excludesFile`, and
`core.ignoreCase`; the rules by which git ignores files, which the page
gitignore gives; and the rules for the names of branches, which the
page git-check-ref-format gives.

From Text and notation (`text`), the design takes characters, code
points, spaces, texts, bytes, byte sequences, 0x numerals, valid UTF-8,
the text of a byte sequence, UTF-8 encodings, lines, line numbers, whole
numbers, code spans, and what a conforming program and a result are.
From Files and paths (`files`), it takes folder trees, folders and their
folder entries, regular files and their contents, symbolic links, files
of another kind, valid paths and their file names, and the files and
the folders of the path of a valid path in a folder tree, file systems,
and the attributes of a file. From the
Ontology (`ontology`), it takes trees, the default branch, and
parameters with their bindings.

From Data forms (`data-forms`), the design takes test-vector sets: the
file that holds the conformance vectors of the design is one. From
POSIX.1-2024, it takes the permissions and the appropriate privileges of
a process, and its user IDs and group IDs.

From RFC 8259, the design takes JSON texts, with their objects,
members, arrays, strings, numbers, and the literal names `true` and
`false`: each line of the file that holds
the conformance vectors of the design is a JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| git | the version control program git |
| git repository | a git folder, with the working trees of the repository |
| [git folder](sinter:#git-folder=v1) | the common folder of a git repository, which holds its object database, the refs that are not those of one working tree, and its file `config`, such as the folder `.git` of its main working tree |
| [working tree](sinter:#working-tree=v1) | the folder tree of the files of a git repository that a person edits, with a folder of its own, which holds its HEAD and git's index; a git repository can have none, one, or more |
| [folder of a working tree](sinter:#working-tree=v1) | the folder that holds the HEAD and git's index of one working tree: the git folder for the main working tree, and a folder inside the folder `worktrees` of the git folder for each other working tree |
| [root folder of a working tree](sinter:#working-tree=v1) | the top folder of a working tree, which usually holds the folder entry `.git` |
| [git configuration](sinter:#git-configuration=v1) | the settings that git 2.43.7 reads for a working tree from the configuration files and the environment variables that the page git-config gives, with `/etc/gitconfig` as the system file and the file `config` of the git folder whatever its owner; for a git repository, the same without the settings of one working tree |
| object database | the git objects that a git repository holds, in its git folder and in the object databases that its alternates name |
| git object | a commit object, a git tree object, or a blob |
| [commit](sinter:#commit=v1) | a commit object that a git repository holds: it names a git tree object and its parents, in order |
| [parent, first parent](sinter:#commit=v1) | a commit that a commit names as one of its parents; the first parent is the first of them; a commit that the file `shallow` names has no parents |
| git tree object | a git object that lists entries; each entry has a name, a mode, and a git object |
| [tree entry, regular-file entry, symbolic-link entry, submodule entry](sinter:#commit-file=v1) | the four types of an entry of a git tree object, which its mode gives |
| blob | a git object that holds a content, which is a byte sequence |
| [reach](sinter:#ancestry=v1) | a commit reaches itself, each of its parents, each parent of each of them, and so on |
| [ancestry](sinter:#ancestry=v1) | the set of the commits that a commit reaches |
| ref | a name, such as `refs/heads/main`, that points to a git object, or that names another ref, as a symbolic ref does |
| [commit of a ref](sinter:#ref-commit=v1) | the commit to which a ref resolves, through the refs that it names in turn, when it resolves to a commit |
| branch | a ref whose name starts with `refs/heads/`, which points to a commit |
| remote-tracking branch | a ref whose name starts with `refs/remotes/`, such as `refs/remotes/origin/main`, which records where a branch of a remote repository pointed |
| [upstream](sinter:#default-branch-commit=v1) | the ref that a branch tracks: the ref that the first value of `branch.<name>.merge` names, mapped by the fetch refspecs of the remote that `branch.<name>.remote` names, or, for the remote `.`, the local ref that it names |
| HEAD | the ref of a working tree that names its current branch, or, when it is detached, points to its current commit |
| [head commit](sinter:#head-commit=v1) | the commit of the HEAD of a working tree |
| git's index | the file of a working tree in which git records the paths of the files that it tracks |
| [excludes file](sinter:#ignored-path=v1) | the file of ignore patterns that the setting `core.excludesFile` names, or, when the setting is not set, the file `git/ignore` in the folder that `XDG_CONFIG_HOME` names, or the file `.config/git/ignore` in the folder that `HOME` names when `XDG_CONFIG_HOME` is not set or is empty |
| [ignored](sinter:#ignored-path=v1) | a path is ignored when git 2.43.7 ignores it, as it decides for a file that its index does not hold, by the rules of the page gitignore, with the patterns of the files `.gitignore`, of the file `info/exclude`, and of the excludes file; when the setting `core.ignoreCase` is true, a pattern matches without regard to the case of the letters from `A` to `Z` |
| shallow clone | a git repository whose file `shallow` names commits whose parents it does not hold |
| partial clone | a git repository that leaves out some git objects, which it can take from a remote repository |
| submodule | a git repository whose working tree is in a folder of the working tree of another git repository; a git tree object names it by a submodule entry |
| jj | Jujutsu, a version control program that can keep its data in a git repository |
| colocated jj repository | a git repository whose working tree also holds the folder `.jj`, in which jj keeps its data |
| [branch name](sinter:#branch-name=v1) | a text b that `git check-ref-format --branch` of git 2.43.7 accepts outside a git repository, and that does not start with `refs/`, such as `main` or `release/2.0` |
| [default branch](sinter:ontology#default-branch=v1) | the branch into which work on a repository merges |
| [commit of the default branch](sinter:#default-branch-commit=v1) | under a binding of `default-branch-name` that is a branch name b, the commit of the first of three refs that exists: the upstream of the branch b, the branch b, and the remote-tracking branch of `origin` for b |
| [parameter](sinter:ontology#parameter=v1), binding | a parameter is a word, such as `default-branch-name`, whose value a design leaves open; a binding of a parameter is a value that configuration gives for it |
| [tree](sinter:ontology#tree=v1) | the set of the files of a repository, with their contents, at one commit or in one working tree |
| [file of the tree of a commit](sinter:#commit-file=v1) | a file that a regular-file entry gives, through the git tree object of the commit, when its path is a valid path that no other entry has |
| [file of the tree of a working tree](sinter:#working-tree-file=v1) | a regular file that a valid path names, through folders, from the root folder of a working tree, when no file name of the path is `.git`, the first is not `.jj`, no folder of the path other than the root holds `.git`, and git tracks the file or does not ignore it |
| [range](sinter:#commit-range=v1) | the set of the commits that one commit reaches and that another commit does not reach |
| [parents-first order](sinter:#parents-first-order=v1) | the order in which a walk from the commit h of a range from s to h, which takes the parents of each commit in their order, finishes the commits of the range; each commit comes after each of its parents in the range |
| [change](sinter:#change=v1) | under a binding under which the default branch has a commit, the change of a commit h: the commits that h, its last commit, reaches and that the commit of the default branch does not reach |
| [last commit of a change](sinter:#change=v1) | the commit h of the change of h, such as the commit to which the branch of a pull request points |
| [common ancestor](sinter:#merge-base=v1) | a commit that each of two commits reaches |
| [merge base](sinter:#merge-base=v1) | a common ancestor of two commits that no other common ancestor of the two reaches |
| [base of a change](sinter:#change-base=v1) | the merge base of the last commit of a change and the commit of the default branch, when there is exactly one |
| [first-parent line](sinter:#first-parent-line=v1) | a commit, its first parent, the first parent of that commit, and so on, up to a commit that has no parent |
| [merge commit](sinter:#merge-commit=v1) | of a commit c on the first-parent line of a commit d: the commit of that first-parent line that reaches c, and that has no parent or whose first parent does not reach c |
| [line texts](sinter:#line-text=v1) | the texts of the lines of the file of a tree with a valid path, in order; none when the tree has no such file or its content is not valid UTF-8 |
| [line map](sinter:#line-map=v1) | the longest set of pairs of the line numbers of the lines of a file in an old tree and in a new tree that have the same text, in the same order; of several, the one whose pairs are least, with the new line number first |
| [hunk](sinter:#hunk=v1) | a part of a file where lines differ between an old tree and a new tree: the lines that it removes from the old tree and the lines that it adds in the new tree, with the line numbers where they start; or a hunk with no line, when no line differs and the file is in one tree only, or its two contents differ and one of them is not valid UTF-8 |
| [diff of a change](sinter:#change-diff=v1) | for each valid path, the hunks between the tree of the base of a change and the tree of its last commit |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [byte sequence](sinter:text#byte-sequence=v1) | a finite sequence of bytes |
| [line](sinter:text#line=v1) | one of the runs into which the line endings of a text divide its body; a line holds no line feed, a carriage return right before a line feed is part of the line ending, a byte order mark is on no line, and an empty run at the end of the body is no line |
| [line number](sinter:text#line-number=v1) | the number of a line of a text, from 1 |
| [valid path](sinter:files#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [folder tree](sinter:files#folder-tree=v1) | a folder, its root, with the file of each folder entry of each of its folders |
| [regular file](sinter:files#regular-file=v1) | a file that holds a content, which is a byte sequence |
| [symbolic link](sinter:files#symbolic-link=v1) | a file that holds a reference, which can lead to a file or to no file |
| [file of another kind](sinter:files#file-of-another-kind=v1) | a file that is not a folder, a regular file, or a symbolic link, such as a pipe |
| [repository read](sinter:#repository-read=v1) | an operation that a program makes to give, for a git repository or a working tree of it, a thing such as a commit, the files of a tree, or the hunks between two trees |
| [conforming program](sinter:text#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |

## 2. Git repositories, changes, and hunks

### 2.1 Git repositories

A git repository has a git folder and zero or more working trees. The
git folder is the common folder of the repository. It holds the object
database, the shared refs, and the configuration of the repository. The
object database holds git objects. A commit object names a git tree
object and its parents. A git tree object lists entries, and each entry
names a blob, a git tree object, or a commit. A blob holds a content.

A working tree is a folder tree with its own HEAD and its own index,
git's index, which are in the folder of the working tree. For the main
working tree, that folder is the git folder, and the root folder of the
working tree usually holds it as the folder `.git`; it can instead hold
a file `.git` that names the git folder, as in a submodule. For a
working tree that `git worktree add` made, the folder of the working
tree is inside the folder `worktrees` of the git folder, and the root
folder of the working tree holds a file `.git` that names it. The files
of a working tree are the files under its root folder, other than
`.git` and the files under `.git`.

A program reads these things of a git repository: its commits, with
their parents and their git tree objects; its blobs; its refs and HEAD;
the git configuration; and, for a working tree, its files, git's index,
and the patterns by which git ignores files. The format of each of them
is the format of git 2.43.7. The git configuration comes from the files
and the environment variables that git 2.43.7 reads, such as the file
`config` of the git folder and the file `.gitconfig` of the home folder.
Its system file is `/etc/gitconfig`, whatever the folder in which a
build of git keeps its own. The file `config` of the git folder counts also
when another user owns the git repository.

A shallow clone is a git repository that leaves out the parents of some
commits. Its file `shallow` names these commits, and each of them has no
parents. A partial clone leaves out some git objects, which git can take
from a remote repository. A program takes no git object from a remote
repository, so in a partial clone it gives no result that needs a git
object that the clone left out. The alternates of a repository, which
its file `objects/info/alternates` names, are part of its object
database. A replacement ref, under `refs/replace/`, and a graft have no
effect on the git objects that a program reads.

Jujutsu, also named jj, is a version control program that can keep its
data in a git repository. A colocated jj repository is a git repository
whose working tree also holds the folder `.jj`, in which jj keeps its
own data. A program reads a colocated jj repository as a git repository.
No file under the folder `.jj` of the root folder is a file of the tree
of the working tree.

### 2.2 Commits, ranges, and their order

Each commit has zero or more parents, in an order. The first of them is
its first parent. Git makes a commit with two or more parents when a
person merges branches. A commit reaches itself, each of its parents, each parent of each
of them, and so on. The ancestry of a commit is the set of the commits
that it reaches.

The range from a commit s to a commit h is the set of the commits that h
reaches and that s does not reach. The range from no commit to h is the
ancestry of h. The parents-first order of a range comes from a walk
that starts at h. To walk a commit, the walk walks each parent of the
commit that is in the range and that it has not started, in the order of
the parents, and then it finishes the commit. The order in which the
walk finishes the commits is the parents-first order. So each commit of
the range comes after each of its parents in the range, and the order
does not depend on the dates of the commits.

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

### 2.3 Branches, HEAD, and the default branch

A branch is a ref under `refs/heads/`, such as `refs/heads/main`, which
points to a commit. A remote-tracking branch is a ref under
`refs/remotes/`, such as `refs/remotes/origin/main`, which records
where a branch of a remote repository pointed when git last fetched it.
A ref can also name another ref, as a symbolic ref does. The commit
of a ref is the commit to which it resolves, through the refs that it
names in turn. The upstream of a branch is the ref that it tracks, often
a remote-tracking branch. The first value of the setting
`branch.<name>.merge` names a ref of a remote, and the setting
`branch.<name>.remote` names that remote. The fetch refspecs of the
remote, the settings `remote.<name>.fetch`, map that ref to the
upstream. For the remote `.`, the upstream is the local ref that the
first value of `branch.<name>.merge` names. So the refspec
`+refs/heads/*:refs/remotes/origin/*` maps `refs/heads/main` to
`refs/remotes/origin/main`.

The HEAD of a working tree is a ref that names a ref, usually a branch,
or, when it is detached, points to a commit. The head commit of the
working tree is the commit of its HEAD. A working tree whose HEAD names
a branch that points to no commit, as in a new repository, has no head
commit. In a colocated jj repository, the HEAD of the working tree is
often detached.

The parameter `default-branch-name` gives the name of the default
branch. A binding of it names the default branch when it is a branch
name: a text b that `git check-ref-format --branch` accepts, and that
does not start with `refs/`. So
`main`, `release/2.0`, and `@` are branch names, and `a..b`, `.hidden`,
`topic.lock`, `a b`, `HEAD`, `-x`, and `refs/heads/main` are not.

The commit of the default branch is the commit of the first of these
refs that exists:

1. the upstream of the branch b;
2. the branch b, `refs/heads/` followed by b;
3. the remote-tracking branch `refs/remotes/origin/` followed by b.

When none of the three exists, or when the first that exists has no
commit, the default branch has no commit.

### 2.4 Changes and their bases

A change is a set of commits that is to merge into the default branch as
one unit, such as the commits of a pull request. Under a binding of
`default-branch-name` under which the default branch has a commit, each
commit h has a change, the change of h. Its commits
are the range from the commit of the default branch to h, and h is its
last commit. In a working tree, the last commit of the change is often
its head commit. When a person merges the default branch into the
branch of a change, no commit of the default branch joins the change,
because the commit of the default branch reaches each such commit.

A common ancestor of two commits is a commit that both of them reach. A
merge base of two commits is a common ancestor that no other common
ancestor of the two reaches. The base of a change is the merge base of
its last commit and the commit of the default branch, when there is
exactly one.

In the example of section 2.2, before git made `f`, the default branch
points to `c`. The change of `e` holds `d` and `e`, and its base is `b`.
When the default branch already reaches the last commit of a change, the
change holds no commit, and its base is its last commit.

Two commits can have no merge base, when their histories share no
commit. They can also have more than one, after merges that cross. For
example, the commits `b` and `c` each have the parent `a`. The commit
`m1` has the parents `b` and `c`, and the commit `m2` has the parents
`c` and `b`. The common ancestors of `m1` and `m2` are `a`, `b`, and
`c`. Both `b` and `c` reach `a`, so the merge bases of `m1` and `m2` are
`b` and `c`. The change of `m1`, while the default branch points to
`m2`, has no base.

### 2.5 First-parent lines and merge commits

The first-parent line of a commit is the commit, its first parent, the
first parent of that commit, and so on, up to a commit that has no
parent. When a person merges a change with a commit that has two
parents, git makes the
commit to which the default branch pointed the first parent of the new
commit, and the last commit of the change its second parent. So the
first-parent line of the default branch passes through each merge into
it, and not through the commits of the merged changes.

For a commit c that a commit d reaches, the merge commit of c on the
first-parent line of d is the commit of that first-parent line that
brought c to it: the commit m of the first-parent line that reaches c,
and that has no parent or whose first parent does not reach c. The
commits of the first-parent line that reach c come first in it, and m is
the last of them.

In the example of section 2.2, the first-parent line of `g` is `g`, `f`,
`c`, `b`, and `a`. The merge commit of `d` and of `e` on that
first-parent line is `f`. The merge commit of `c` is `c` itself. When a
person brings the work of a change to the default branch as one squash
commit, or as commits that the default branch fast-forwards to when the
change holds no commit with two or more parents, each such commit is on
the first-parent line, and it is its own merge commit.

### 2.6 The files of a tree

A tree is the set of the files of a repository, with their contents, at
one commit or in one working tree. Each file of a tree has a valid path
and a content, which is a byte sequence.

The files of the tree of a commit come from the git tree object of the
commit. Each entry of a git tree object has a name, a mode, and a git
object. The mode is a number in base 8. Its type bits, the bits that
0170000 in base 8 selects, give the type of the entry, as git 2.43.7
reads it:

| type bits, in base 8 | type of the entry | the entry names |
|---|---|---|
| 040000 | tree entry | a git tree object, which lists more entries |
| 100000 | regular-file entry | the blob of a regular file, such as with the mode 100644, or 100755 for an executable file |
| 120000 | symbolic-link entry | the blob of a symbolic link |
| any other, such as 160000 | submodule entry | a commit of another repository |

The byte path of an entry is the byte sequence of the names of the
entries on the way to it, with the byte of `/` between each two names.
Each regular-file entry whose byte path is the UTF-8 encoding of a valid
path gives one file, with the content of its blob. A symbolic-link entry and a submodule entry give no file. An entry
whose name holds `/` gives no file, and the entries under it give none.
When two entries have the same byte path, neither gives a file. A git tree
object of which git 2.43.7 cannot decode an entry lists no entries: an
entry whose mode is empty or holds a character other than the digits
from 0 to 7, such as the digit 8, an entry whose name is empty, or an
entry that the end of the git tree object cuts short.

The files of the tree of a working tree come from the files on disk. A
regular file of the working tree is a file of its tree when it meets
each of these conditions:

| condition | so these files are not in the tree |
|---|---|
| a valid path names it, through folders, from the root folder | a file behind a symbolic link, and a file whose name is not valid UTF-8 |
| no file name of its path is `.git`, and the first is not `.jj` | the files of the git folder, the file `.git` of a working tree, and the files of jj |
| no folder of its path, other than the root, holds the folder entry `.git` | the files of a submodule and of each other git repository inside the working tree |
| git's index holds its path, or its path is not ignored | an untracked file that a pattern of a file `.gitignore` matches |

A path is ignored when git 2.43.7 ignores it, as it decides for a file
that its index does not hold. The patterns come from the files
`.gitignore` of the working tree, from the file `info/exclude` of the git
folder, and from the excludes file: the file that the setting
`core.excludesFile` names, or, when the setting is not set, the file
`git/ignore` in the folder that the environment variable
`XDG_CONFIG_HOME` names, or the file `.config/git/ignore` in the folder
that the environment variable `HOME` names when `XDG_CONFIG_HOME` is not
set or is empty. When the setting `core.ignoreCase` is true, a pattern
matches without regard to the case of the letters from `A` to `Z`.

The content of each file is its content on disk. So a file that git
tracks and that a person changed after the last commit has its new
content, whatever git's index records about it. A tracked file that a
person deleted is not in the tree, and a file that git neither tracks
nor ignores is in the tree. No setting of git and no git attribute,
which a file `.gitattributes` gives, changes the content of a file of a
tree, such as by a filter or by a conversion of line endings.

Example: the root folder of a working tree holds `.git`, `.gitignore`
with the pattern `build/`, `a.md`, a symbolic link `link` to the folder
`docs`, the folder `docs` with `b.md`, the folder `build` with `out.md`,
and the folder `lib` of a submodule, with its file `.git` and its file
`c.md`. The files of the tree of the working tree are `.gitignore`,
`a.md`, and `docs/b.md`.

### 2.7 Line texts, line maps, and hunks

Two trees, an old tree and a new tree, can hold a file with the same
valid path. The line texts of a valid path in a tree are the texts of
the lines of the text of the content of that file, in the order of
their line numbers. A tree that has no file with the valid path, or whose file with
it has a content that is not valid UTF-8, gives no line texts. A line
holds no line ending, so two contents that differ only in their line
endings, or only in a byte order mark, give the same line texts.

A map of a valid path between the two trees pairs some old lines with
new lines that have the same text, in the same order. The line map is a
longest map: no map has more pairs. Several longest maps can exist when
lines repeat. The line map is the one whose pairs are least, one after
the other, where the less of two pairs is the one with the less new
line number, or with the less old line number when their new line
numbers are the same. So when lines repeat, the line map pairs the
earlier of two equal lines.

The lines between two pairs of the line map that follow one another,
or before its first pair, or after its last pair, form a hunk. A hunk has
an old start, the line number of the first line that it removes; the
number of the lines that it removes; a new start, the line number of the
first line that it adds; and the number of the lines that it adds. When
a hunk removes no line, its old start is the line number of the old line
that comes right after the lines that it adds. When a hunk adds no line,
its new start is the line number of the new line that comes right after
the lines that it removes, which is 1 more than the number of new lines
when the removed lines are at the end.

Example: the old content is `one`, `two`, `three`, each line with a line
ending. The new content is `one`, `2`, `three`, `four`. The line map
is the pairs (1, 1) and (3, 3). There are two hunks: one with the old
start 2, one line removed, the new start 2, and one line added; and one
with the old start 4, no line removed, the new start 4, and one line
added.

| old | new | hunks: old start, removed, new start, added |
|---|---|---|
| no file | `x`, `y` | 1, 0, 1, 2 |
| `x`, `y`, `z` | no file | 1, 3, 1, 0 |
| `x` | `x`, `x` | 2, 0, 2, 1 |
| `a`, `b` | `b`, `a` | 1, 1, 1, 0 and 3, 0, 2, 1 |
| `a`, `b`, with carriage returns | `a`, `b` | none |

A file can differ between the two trees while the line map gives no
hunk. Then the valid path of the file has one hunk with no line, with the old
start 1, no line removed, the new start 1, and no line added, when the
file is in one tree only, such as an empty file, or when one of its two
contents is not valid UTF-8. When both contents are valid UTF-8 and give
the same line texts, such as two contents that differ only in their line
endings, the valid path has no hunk. A valid path whose file is the same in both
trees has no hunk. A file that moves to another valid path has the hunks
of a file removed at its old path and of a file added at its new path.

The diff of a change gives, for each valid path, the hunks between the
tree of the base of the change and the tree of its last commit.

### 2.8 What a program guarantees

A program that reads a git repository changes no file of it, in its git
folder or in a working tree. It takes no git object from a remote
repository, such as the remote repository of a partial clone. It takes
bytes only from the folders and the regular files of the repository, of
its git configuration, and of the excludes file. It uses no permission
or privilege that its process does not have. In a working tree, it
follows no symbolic link, and it does not wait for a process or a
device to act on a file of another kind, such as a pipe. It runs no
program that the git configuration or a file of the repository names,
such as a hook or a filter. When another process changes the git
repository, a working tree, the git configuration, or the excludes file
during a repository read, what the program gives in that read is not
specified, and these guarantees still hold.

## 3. Parameters

### 3.1 `default-branch-name`

The parameter `default-branch-name` gives the name of the default branch
of a git repository. A binding of it is a text. Under a binding that is
a branch name b, the default branch is the branch `refs/heads/` followed
by b. Under a binding that is not a branch name, the default branch has
no commit.

## 4. Definitions

### 4.1 Git folders

@term git-folder=v1
@cites {git/2.43.7, files#{folder=v1}, text#{code-span=v1}}

The git folder of a git repository is its common folder, as the page
gitrepository-layout of git 2.43.7 defines the common folder. It holds
the object database of the git repository, its refs other than the refs
of one working tree, and its file `config`.

### 4.2 Working trees

@term working-tree=v1
@cites {
    git/2.43.7,
    files#{folder=v1, folder-tree=v1},
    text#{code-span=v1},
    #{git-folder=v1},
}

A working tree of a git repository, as git 2.43.7 defines it, has a root
folder, which is the root of the folder tree of the files that a person
edits, and a folder of its own, which holds the HEAD of that working
tree and its index, git's index. The folder of the main working tree is
the git folder. The folder of each other working tree is a folder inside
the folder `worktrees` of the git folder. Git's index of a working tree
is the file `index` in the folder of that working tree, whatever the
environment variable `GIT_INDEX_FILE` names. The files of a working tree
are the files of the folder tree whose root is its root folder, other
than the file of the folder entry `.git` of the root folder and, when
that file is a folder, the files of the folder tree whose root is that
folder.

### 4.3 Git configurations

@term git-configuration=v1
@cites {git/2.43.7, text#{code-span=v1}, #{git-folder=v1, working-tree=v1}}

The git configuration of a working tree of a git repository is the set
of the settings that git 2.43.7 reads for that working tree, in the
environment of the program, from the configuration files and the
environment variables that the page git-config of git 2.43.7 gives, and
from the files that they include, with these rules:

1. The system file is the file that the environment variable
   `GIT_CONFIG_SYSTEM` names, or, when that variable is not set, the
   file `/etc/gitconfig`. There is no system file when the environment
   variable `GIT_CONFIG_NOSYSTEM` is true.
2. The file `config` of the git folder is read whatever the owner of the
   git repository and whatever the setting `safe.directory`.

The git configuration of a git repository is the same set without the
settings of the file `config.worktree` of each working tree and without
the sections `includeIf` whose condition starts with `onbranch:`. A
setting has its value as git 2.43.7 reads it: a boolean setting is true
when git 2.43.7 reads its value as true, and a setting whose value
names a file names the file that git 2.43.7 finds for its value as a
pathname, with a relative pathname taken from the root folder of the
working tree.

### 4.4 Commits

@term commit=v1
@cites {git/2.43.7, text#{code-span=v1}, #{git-folder=v1}}

A git repository holds a git object when the object database of its git
folder holds that git object, or when an object database that git 2.43.7
finds from it through the files `objects/info/alternates` holds it, as
git 2.43.7 defines git objects, object databases, and alternates. A
commit of a git repository is a commit object, as git 2.43.7 defines it,
that the git repository holds. A commit names one git tree object, the
git tree object of the commit, and zero or more commits, its parents, in
an order. The first of its parents is its first parent. A commit that
the file `shallow` of the git folder names has no parents. The content
of a blob, the entries of a git tree object, and the git tree object and
the parents of a commit are those that the git object itself holds: no
replacement ref, which is a ref whose name starts with `refs/replace/`,
and no graft, which a line of the file `info/grafts` of the git folder
gives, has an effect on them.

### 4.5 Ancestry

@term ancestry=v1
@cites #{commit=v1}

The ancestry of a commit c is the smallest set of commits that holds c
and that holds each parent of each commit that it holds. A commit c
reaches each commit of its ancestry, c included, and no other commit.

### 4.6 The commits of refs

@term ref-commit=v1
@cites {git/2.43.7, #{git-folder=v1, working-tree=v1, commit=v1}}

A ref of a git repository, or of a working tree of it, points to a git
object or names another ref, as git 2.43.7 defines refs and symbolic
refs. A ref exists when the git repository, or the working tree, holds
a ref with that name, whatever it points to or names. The commit of a
ref is the git object to which git 2.43.7 resolves that ref, through the
refs that it names in turn, when that git object is a commit of the git
repository. A ref that does not exist, or that resolves to no commit of
the git repository, has no commit.

### 4.7 Head commits

@term head-commit=v1
@cites {git/2.43.7, #{working-tree=v1, ref-commit=v1}}

The HEAD of a working tree is a ref of that working tree, in the folder
of that working tree, as git 2.43.7 defines it: it names a ref, or, when
it is detached, it points to a git object. The head commit of a working
tree is the commit of its HEAD. A working tree whose HEAD has no commit
has no head commit.

### 4.8 Branch names

@term branch-name=v1
@cites {
    git/2.43.7,
    text#{text=v1, character=v1, code-point=v1, space=v1, code-span=v1},
}

The parts of a text are the texts between its characters `/`: the text
before the first `/`, each text between a `/` and the next `/`, and the
text after the last `/`. A text with no `/` has one part, which is the
text. A branch name is a text b that meets each of these conditions.
Conditions 1 to 7 are the rules of `git check-ref-format --branch` of
git 2.43.7 for b, when it runs outside a git repository.

1. b is not empty. It does not start with `/`, it does not end with
   `/`, and it does not hold `//`.
2. No part of b starts with `.` or ends with `.lock`.
3. b does not hold `..` or `@{`.
4. b does not end with `.`.
5. b holds no character whose code point is from 0 to 31, and no
   character whose code point is 127.
6. b holds no space and none of the characters `~`, `^`, `:`, `?`, `*`,
   `[`, and `\`.
7. b is not `HEAD`, and it does not start with `-`.
8. b does not start with `refs/`.

### 4.9 The commit of the default branch

@term default-branch-commit=v1
@cites {
    git/2.43.7,
    ontology#{default-branch=v1, parameter=v1},
    text#{code-span=v1},
    #{git-configuration=v1, ref-commit=v1, branch-name=v1},
}

Under a binding of the parameter `default-branch-name` that is a branch
name b, the default branch of a git repository is the branch whose ref
name is `refs/heads/` followed by b, and these are the three refs of the
default branch, in this order:

1. the upstream of b. Let M be the first value of the setting
   `branch.<name>.merge`, and r the last value of the setting
   `branch.<name>.remote`, each with b for `<name>`, in the
   git configuration of the git repository. When r is `.`, the upstream
   of b is the ref that git 2.43.7 finds for M as the name of a ref, such
   as `refs/heads/develop` for `develop`. Otherwise, it is the ref to
   which git 2.43.7 maps M with the fetch refspecs of the remote r, which
   the settings `remote.<name>.fetch` with r for `<name>`
   give. When one of the two settings has no value, or when no fetch
   refspec of r maps M, b has no upstream.
2. the ref whose name is `refs/heads/` followed by b.
3. the ref whose name is `refs/remotes/origin/` followed by b.

The commit of the default branch is the commit of the first of these
three refs that exists in the git repository. When none of them exists,
or when the first of them that exists has no commit, the default branch
has no commit. Under a binding of `default-branch-name` that is not a
branch name, the default branch has no commit.

### 4.10 The files of the tree of a commit

@term commit-file=v1
@cites {
    git/2.43.7,
    ontology#{tree=v1},
    files#{path=v1},
    text#{
        byte-sequence=v1, byte=v1, utf-8-encoding=v1, 0x-numeral=v1,
        whole-number=v1,
    },
    #{commit=v1},
}

A git tree object lists entries, as git 2.43.7 defines them. Each entry
has a name, which is a byte sequence; a mode, which is the whole number
that the digits of the mode write in base 8; and a git object. Let t be
the whole-number quotient of r divided by 4096, where r is the remainder
of the mode divided by 65536. As git 2.43.7 reads the mode, each entry is
of one of four types:

1. a tree entry, when t is 4: it names a git tree object;
2. a regular-file entry, when t is 8: it names a blob;
3. a symbolic-link entry, when t is 10;
4. a submodule entry, for each other t.

A git tree object lists no entries for these rules when git 2.43.7
cannot decode one of its entries: when the mode of an entry is empty or
holds a character other than the digits from 0 to 7, when the name of an
entry is empty, or when the git tree object ends before the end of the
object id of an entry. The entries of a git tree object T, each with
its byte path, which is a byte sequence, are these: each entry that T
lists and whose name holds no byte 0x2F, with its name as its byte path;
and, for each tree entry D among them, each entry of the git tree object
that D names, with the byte path of D, then the byte 0x2F, then its byte
path in that git tree object.

The files of the tree of a commit are these, and no others: for each
regular-file entry E of the git tree object of the commit whose byte
path is the UTF-8 encoding of a valid path p, and such that no other
entry of that git tree object has the same byte path as E, the file
whose valid path is p and whose content is the content of the blob that
E names.

### 4.11 Ignored paths

@term ignored-path=v1
@cites {
    git/2.43.7,
    text#{code-span=v1},
    #{git-folder=v1, working-tree=v1, git-configuration=v1},
}

The excludes file of a working tree is the file that the setting
`core.excludesFile` names in the git configuration of the working tree.
When that setting has no value, the excludes file is the file
`git/ignore` in the folder that the environment variable
`XDG_CONFIG_HOME` of the program names, or, when that variable is not
set or is empty, the file `.config/git/ignore` in the folder that the
environment variable `HOME` of the program names.

A path is ignored in a working tree when git 2.43.7, with the git
configuration of the working tree, ignores that path in the working
tree, as it decides for a file that git's index does not hold, by the
rules that the page gitignore of git 2.43.7 gives: with the patterns of
the files `.gitignore` of the working tree, of the file `info/exclude`
of the git folder, and of the excludes file. In that decision, a pattern
matches without regard to the case of the letters from `A` to `Z` when,
and only when, the setting `core.ignoreCase` is true in that git
configuration.

### 4.12 The files of the tree of a working tree

@term working-tree-file=v1
@cites {
    ontology#{tree=v1},
    files#{folder-tree=v1, folder=v1, regular-file=v1, path=v1, path-file=v1},
    text#{text=v1, utf-8-encoding=v1, code-span=v1},
    #{working-tree=v1, ignored-path=v1},
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

### 4.13 Ranges

@term commit-range=v1
@cites #{commit=v1, ancestry=v1}

For two commits s and h of a git repository, the range from s to h is
the set of the commits that h reaches and that s does not reach. The
range from no commit to h is the set of the commits that h reaches.

### 4.14 Parents-first orders

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

### 4.15 Changes

@term change=v1
@cites {
    ontology#{default-branch=v1, parameter=v1},
    text#{code-span=v1},
    #{commit=v1, commit-range=v1, default-branch-commit=v1},
}

Under a binding of `default-branch-name` under which the default branch
of a git repository has a commit d, each commit h of the git repository
has one change under that binding, the change of h. The last commit of
that change is h, and the commits of that change are the commits of the
range from d to h.

### 4.16 Merge bases

@term merge-base=v1
@cites #{commit=v1, ancestry=v1}

A common ancestor of two commits is a commit that each of the two
reaches. A merge base of two commits is a common ancestor of the two
that no other common ancestor of the two reaches.

### 4.17 The base of a change

@term change-base=v1
@cites {
    ontology#{parameter=v1},
    text#{code-span=v1},
    #{commit=v1, change=v1, merge-base=v1, default-branch-commit=v1},
}

The base of a change under a binding of `default-branch-name` is the
merge base of the last commit of the change and the commit of the
default branch under that binding, when these two commits have exactly
one merge base. A change whose last commit and the commit of the default
branch have no merge base, or more than one, has no base.

### 4.18 First-parent lines

@term first-parent-line=v1
@cites #{commit=v1}

The first-parent line of a commit c is the sequence of commits that
starts with c, in which each other commit is the first parent of the
commit right before it, and whose last commit has no parent.

### 4.19 Merge commits

@term merge-commit=v1
@cites #{commit=v1, ancestry=v1, first-parent-line=v1}

For a commit d and a commit c that d reaches, the merge commit of c on
the first-parent line of d is the commit m of that first-parent line
that reaches c, and that has no parent or whose first parent does not
reach c. The commits of that first-parent line that reach c come first
in it, so m is the last of them. A commit that d does not reach has no
merge commit on the first-parent line of d.

### 4.20 Line texts

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

### 4.21 Line maps

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
only when, j < j′. A map is longest when no map of p between A and B has
more pairs. One pair (i, j) is less than another pair (i′, j′) when
j < j′, or when j = j′ and i < i′. The line map of p between A and B is
the longest map M such that, for each other longest map N, the least of
the pairs that are in one of M and N and not in the other is in M.

### 4.22 Hunks

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

For a valid path p, an old tree A, and a new tree B, let m and n be the
numbers of the line texts of p in A and in B. Let P be the set of the
pairs of the line map of p between A and B, with the pair (0, 0) and the
pair (m + 1, n + 1). The next pair of a pair (i, j) of P, other than
(m + 1, n + 1), is the pair of P whose first number is the least first
number of P that is greater than i. Each pair (i, j) of P whose next
pair (i′, j′) has i′ > i + 1 or j′ > j + 1 gives p one hunk between A and
B, which has four whole numbers: its old start, i + 1; the number of the
lines that it removes, i′ − i − 1; its new start, j + 1; and the number
of the lines that it adds, j′ − j − 1. The lines that such a hunk
removes are the lines of the text of the content of the file of A with
the valid path p, from the line whose line number is its old start, as
many as it removes. The lines that it adds are the lines of the text of
the content of the file of B with the valid path p, from the line whose
line number is its new start, as many as it adds.

When the pairs of P give p no hunk, p has one hunk between A and B, with
the old start 1, no line that it removes, the new start 1, and no line
that it adds, when one of these holds:

1. A has a file whose valid path is p, and B has none.
2. B has a file whose valid path is p, and A has none.
3. A and B each have a file whose valid path is p, the contents of the
   two are not the same byte sequence, and the content of one of them is
   not valid UTF-8.

The hunks of p between A and B are the hunks that these rules give, and
no others.

### 4.23 The diff of a change

@term change-diff=v1
@cites {
    ontology#{tree=v1},
    files#{path=v1},
    #{change=v1, change-base=v1, commit-file=v1, hunk=v1},
}

The diff of a change that has a base gives, for each valid path p, the
hunks of p between the tree of the base of the change, as the old tree,
and the tree of the last commit of the change, as the new tree. A change
that has no base has no diff.

### 4.24 Repository reads

@term repository-read=v1
@cites {
    ontology#{tree=v1},
    files#{path=v1},
    #{
        working-tree=v1, commit=v1, ancestry=v1, ref-commit=v1,
        head-commit=v1, default-branch-commit=v1, commit-file=v1,
        working-tree-file=v1, commit-range=v1, parents-first-order=v1,
        change=v1, merge-base=v1, change-base=v1, first-parent-line=v1,
        merge-commit=v1, line-map=v1, hunk=v1, change-diff=v1,
    },
}

A repository read is an operation that a program makes to give, for a
git repository or for a working tree of it, one or more of these
things, also when the program gives another thing in it, or nothing:
the parents of a commit; whether a commit reaches
another; the commit of a ref; the head commit of a working tree; the
commit of the default branch; the files of the tree of a commit or of a
working tree; the commits of a range or of a change, or their
parents-first order; merge bases, or the base of a change; a
first-parent line, or a merge commit; and the hunks, the line map, or
the line numbers of a valid path between two trees of the git
repository, or the diff of a change.

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
@cites {#{commit=v1, ancestry=v1, repository-read=v1}, text#{conforming-program=v1, result=v1}}

When, in a repository read during which no other process changes the
git repository, a conforming program gives a result for whether a
commit c reaches a commit c′ of that git repository, it must give
exactly one result: "reaches" when c reaches c′, and "does not
reach" when c does not reach c′.

### 5.3 Parents

@req give-commit-parents=v1
@cites {#{commit=v1, repository-read=v1}, text#{conforming-program=v1}}

When it gives the parents of a commit of a git repository, in a
repository read during which no other process changes the git
repository, a conforming program must give exactly the parents of that
commit, in their order.

### 5.4 The commits of refs

@req give-ref-commits=v1
@cites {#{ref-commit=v1, repository-read=v1}, text#{conforming-program=v1}}

In a repository read during which no other process changes the git
repository, a conforming program must give, as the commit of a ref of
that git repository, only the commit of that ref, and no commit when
that ref has no commit.

### 5.5 The commit of the default branch

@req give-default-branch-commits=v1
@cites {
    #{commit=v1, git-configuration=v1, default-branch-commit=v1, repository-read=v1},
    ontology#{default-branch=v1, parameter=v1},
    text#{conforming-program=v1, code-span=v1},
}

In a repository read during which no other process changes the git
repository or the git configuration, a conforming program must give, as
the commit of the default branch of that git repository under a binding
of `default-branch-name`, only the commit of the default branch under
that binding, and no commit when the default branch has no commit under
that binding.

### 5.6 Head commits

@req give-head-commits=v1
@cites {
    #{commit=v1, working-tree=v1, head-commit=v1, repository-read=v1},
    text#{conforming-program=v1},
}

In a repository read during which no other process changes the git
repository or the working tree, a conforming program must give, as the
head commit of a working tree of that git repository, only the head
commit of that working tree, and no commit when that working tree has no
head commit.

### 5.7 The files of the tree of a commit

@req give-commit-files=v1
@cites {
    #{commit=v1, commit-file=v1, repository-read=v1},
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When it gives the valid paths of the files of the tree of a commit of a
git repository, or those files, in a repository read during which no
other process changes the git repository, a conforming program must
give exactly the valid paths of the files of
the tree of that commit, and, as the content of each file, only the
content of that file.

### 5.8 The files of the tree of a working tree

@req give-working-tree-files=v1
@cites {
    #{working-tree=v1, git-configuration=v1, ignored-path=v1, working-tree-file=v1, repository-read=v1},
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When it gives the valid paths of the files of the tree of a working
tree of a git repository, or those files, in a repository read during
which no other process changes the git repository, the working tree,
the git configuration, or the excludes file, a conforming program must
give exactly the valid
paths of the files of the tree of that working tree, and, as the content
of each file, only the content of that file.

### 5.9 Ranges

@req give-ranges=v1
@cites {#{commit=v1, commit-range=v1, repository-read=v1}, text#{conforming-program=v1}}

When it gives the commits of the range from a commit, or from no commit,
to a commit of a git repository, in a repository read during which no
other process changes the git repository, a conforming program must give
exactly the commits of that range.

### 5.10 Parents-first orders

@req give-parents-first-orders=v1
@cites {
    #{commit=v1, commit-range=v1, parents-first-order=v1, repository-read=v1},
    text#{conforming-program=v1},
}

When it gives the commits of a range of a git repository, in a
repository read during which no other process changes the git
repository, in an order that it gives as their parents-first order, a
conforming program must give them in the parents-first order of
that range.

### 5.11 Changes

@req give-changes=v1
@cites {
    #{commit=v1, git-configuration=v1, change=v1, default-branch-commit=v1, repository-read=v1},
    ontology#{default-branch=v1, parameter=v1},
    text#{conforming-program=v1, code-span=v1},
}

In a repository read during which no other process changes the git
repository or the git configuration, a conforming program must give, as
the commits of the change of a commit h of that git repository under a
binding of `default-branch-name`, exactly the commits of the change of h, and no set of commits when the
default branch has no commit under that binding.

### 5.12 Merge bases

@req give-merge-bases=v1
@cites {#{commit=v1, merge-base=v1, repository-read=v1}, text#{conforming-program=v1}}

When it gives the merge bases of two commits of a git repository, in a
repository read during which no other process changes the git
repository, a conforming program must give exactly the merge bases of
those two commits.

### 5.13 The base of a change

@req give-change-bases=v1
@cites {
    #{commit=v1, git-configuration=v1, change=v1, change-base=v1, repository-read=v1},
    text#{conforming-program=v1},
}

In a repository read during which no other process changes the git
repository or the git configuration, a conforming program must give, as
the base of a change in that git repository, only the base of that
change, and no commit when that
change has no base.

### 5.14 First-parent lines

@req give-first-parent-lines=v1
@cites {#{commit=v1, first-parent-line=v1, repository-read=v1}, text#{conforming-program=v1}}

When it gives the first-parent line of a commit of a git repository, in
a repository read during which no other process changes the git
repository, a conforming program must give exactly the commits of that
first-parent line, in the order of that first-parent
line.

### 5.15 Merge commits

@req give-merge-commits=v1
@cites {
    #{commit=v1, ancestry=v1, first-parent-line=v1, merge-commit=v1, repository-read=v1},
    text#{conforming-program=v1},
}

In a repository read during which no other process changes the git
repository, a conforming program must give, as the merge commit of a
commit c on the first-parent line of a commit d of that git repository,
only the merge commit of c on that first-parent line, and
no commit when d does not reach c.

### 5.16 Hunks

@req give-hunks=v1
@cites {
    #{
        hunk=v1, repository-read=v1, working-tree=v1, git-configuration=v1,
        ignored-path=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

When it gives the hunks of a valid path between an old tree and a new
tree, a conforming program must give exactly the hunks of that valid
path between those trees, each with its old start, the number of the
lines that it removes, its new start, and the number of the lines that
it adds, when neither tree is the tree of a working tree, and when one of
them is the tree of a working tree, in a repository read during which no
other process changes the git repository, that working tree, the git
configuration, or the excludes file.

### 5.17 The line numbers of lines that stay

@req give-new-line-numbers=v1
@cites {
    #{
        line-map=v1, repository-read=v1, working-tree=v1,
        git-configuration=v1, ignored-path=v1,
    },
    ontology#{tree=v1},
    files#{path=v1},
    text#{
        conforming-program=v1, line=v1, line-number=v1, whole-number=v1,
        text-of-a-byte-sequence=v1,
    },
}

When neither of two trees is the tree of a working tree, and, when one
of them is the tree of a working tree, in a repository read during which
no other process changes the git repository, that working tree, the git
configuration, or the excludes file, a conforming program must give, as
the new line number of the old line i of a valid path p between the old
tree and the new tree, only the whole number j such that the line map of
p between those trees holds the pair (i, j), and no line number when the
line map holds no pair whose first number is i.

### 5.18 The diff of a change

@req give-change-diffs=v1
@cites {
    #{git-configuration=v1, change=v1, change-diff=v1, hunk=v1, repository-read=v1},
    files#{path=v1},
    text#{conforming-program=v1},
}

In a repository read during which no other process changes the git
repository or the git configuration, a conforming program must give, as
the diff of a change in that git repository, only the diff of that
change, with exactly the hunks of
each valid path, each with its old start, the number of the lines that
it removes, its new start, and the number of the lines that it adds, and
no diff when that change has no base.

### 5.19 No change to the repository

@req keep-repositories-unchanged=v1
@cites {
    #{git-folder=v1, working-tree=v1, repository-read=v1},
    files#{file-system=v1, attribute=v1},
    text#{conforming-program=v1},
}

In each repository read, a conforming program, itself or through a
program that it runs, such as git, must not create, delete, or change a
file, or change an attribute of a file, in the git folder of the git
repository, in the folder of a working tree of it, or in the folder tree
whose root is the root folder of such a working tree, and must not
delete or change a file that it reads in that repository read, or an
attribute of such a file. When the program uses a file, the file system
can itself change an attribute of that file, such as its time of last
access; the program does not change that attribute.

### 5.20 Git objects only from the repository

@req take-objects-only-from-repositories=v1
@cites {#{commit=v1, repository-read=v1}, text#{conforming-program=v1}}

In each repository read, a conforming program, itself or through a
program that it runs, such as git, must take each git object that it
uses from the git objects that the git repository holds, and none from
a remote repository, such as the remote repository of a partial clone.

### 5.21 Bytes only from the files of the repository

@req read-only-repository-files=v1
@cites {
    #{
        git-folder=v1, working-tree=v1, git-configuration=v1,
        ignored-path=v1, commit=v1, repository-read=v1,
    },
    git/2.43.7,
    files#{folder=v1, regular-file=v1, taken-byte=v1},
    text#{conforming-program=v1, code-span=v1},
}

In each repository read, a conforming program, itself or through a
program that it runs, such as git, must take bytes only from folders and
regular files that are in the git folder of the git repository, in an
object database that git 2.43.7 finds from it through the files
`objects/info/alternates`, in the folder of a working tree of it, or
among the files of such a working tree, and from the regular files of
the git configuration and the excludes file.

### 5.22 No permission or privilege that the process did not have

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
processes, that its process has without a change by the program: not
one that it gets by a change of the user IDs, the group IDs, or the
appropriate privileges of its process, or through another process that
acts for it.

### 5.23 No program that the repository names

@req run-no-configured-programs=v1
@cites {
    #{git-configuration=v1, repository-read=v1},
    text#{conforming-program=v1, code-span=v1},
}

In each repository read, a conforming program, itself or through a
program that it runs, such as git, must run no program that the git
configuration or a file of the git repository names, such as a hook, a
filter, a diff driver, or the program of the setting `core.fsmonitor`.

### 5.24 No symbolic link followed in a working tree

@req follow-no-working-tree-links=v1
@cites {
    #{
        working-tree=v1, git-configuration=v1, ignored-path=v1,
        repository-read=v1,
    },
    files#{symbolic-link=v1},
    text#{conforming-program=v1},
}

In each repository read for a working tree, a conforming program must
follow no symbolic link that is a file of that working tree, other than
a file that git 2.43.7 reads for the git configuration or as the
excludes file: it must find no file by the reference of such a symbolic
link.

### 5.25 No wait in a working tree

@req avoid-working-tree-waits=v1
@cites {
    #{working-tree=v1, repository-read=v1},
    files#{file-of-another-kind=v1},
    text#{conforming-program=v1},
}

In each repository read for a working tree, a conforming program must
not wait for another process or for a device to act on a file of another
kind that is a file of that working tree, such as for a process to open
the other end of a pipe.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`changes.test-vectors.jsonl`](changes.test-vectors.jsonl), in the same
folder as this design. A vector is an input and what a conforming
program gives for it. Each vector follows from the requirements and adds
nothing to them. The vectors are in groups. Each group has a name, such
as `hunks`, and a subsection below. The subsection names the
requirements that the vectors of the group follow from, and it describes
their inputs, results, and values. Each vector of a group follows from
one or more of these requirements. The requirements
`keep-repositories-unchanged`, `take-objects-only-from-repositories`,
`read-only-repository-files`, `gain-no-repository-privileges`,
`run-no-configured-programs`, `follow-no-working-tree-links`, and
`avoid-working-tree-waits` name no result for an input, so no vector
follows from them.

Most requirements apply only when a program gives the thing that they
name, such as the base of a change. So a vector holds a program only to
what the program gives for the input. The subsection of each group says
what a conforming program gives in each case. When a subsection says
that a conforming program gives a thing, such as the merge commit of
`merge-commits`, it gives that thing and no other thing of the same
kind, such as no other merge commit for the same two commits.

The input of a vector stands for a git repository, a working tree, or
two trees, in the forms that the subsection of its group gives. A vector
names each commit by a short name, such as `a`, which stands for that
commit. The git repository of a vector holds the commits that its input
names, and no other commit.

The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1). Each line of the
file is the canonical byte sequence of one JSON object, then the byte
0x0A, so each line is a JSON text, as RFC 8259 defines it. The file is
valid UTF-8. It has no byte order mark and no carriage return, and it
ends with a line feed. Only a line feed ends a line of the file. A character U+FEFF inside a
JSON string of the file is a character of that string, and not a byte
order mark. The file has three kinds of line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `branch-names`,
   `change-diffs`, `changes`, `commit-files`, `default-branch-commits`,
   `head-commits`, `hunks`, `merge-commits`, `parents`, `ranges`,
   `reach`, `ref-commits`, `working-tree-files`. Its JSON object has two members: `group`, the
   name of the group, as a JSON string, and `rev`, the revision of the
   group.
3. Then each vector has a vector line, in increasing order of the
   numbers of the vectors.

The JSON object of a vector line has these members:

- `n`: the number of the vector, a JSON number written as the decimal
  numeral of a whole number of 1 or more. No other vector of the file
  has this number. A number is given to one vector only: when a vector
  leaves the file, no later vector gets its number, and a new vector
  gets a number greater than each number before it.
- `rev`: the revision of the vector.
- `group`: the name of the group of the vector, as a JSON string.
- `input`: the input.
- `result`: the result that a conforming program gives when it gives a
  result for the input. Only a vector of the groups `branch-names` and
  `reach` has this member.
- `values`: a JSON object that holds what a conforming program gives
  for the input, other than the result. Each vector of a group other
  than `branch-names` and `reach` has this member. The subsection of the group says
  which of these things a conforming program gives in each case. An
  empty JSON object, `{}`, says that a conforming program gives none of
  the things that the subsection names for `values`.
- `note`: an explanation of the vector, as a JSON string, which a
  conforming program does not give. A vector has this member only when
  it has an explanation.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of the set line is the
revision of the whole set, the revision of a group line is the revision
of the group, and the revision of a vector line is the revision of the
vector. A revision rises, to a greater number after its `v`, when the
vectors that it covers change, join, or leave. When the text of this
section changes, the revisions of every vector, every group, and the set
rise. When only the note of a vector changes, no revision rises. A program does not
need the revisions to run the vectors.

Inside the members `input`, `result`, and `values`, each JSON value that
the subsection of a group names as a text, a byte sequence, a whole
number, a commit, a commit graph, a tree, a sequence, or a set has this
form:

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
- A commit is a JSON string: the name of the commit in the vector.
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
- A sequence, such as the commits of a first-parent line, is a JSON
  array of its elements, in order.
- A set of texts, such as the merge bases of two commits or the valid
  paths of the files of a tree, is a JSON array of its elements, each
  once, in code point order. Of two different texts, the one that comes
  first in code point order is the one whose character comes first in
  code point order at the first place where the two differ, or, when one
  of them starts with the other, the shorter one.

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
{"group":"branch-names","input":"main","n":1,"result":"valid","rev":"v1"}
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
  empty JSON object, `{}`, when that ref has no commit: `upstream` for the upstream of the branch b, which the
  settings `branch.<name>.remote` and `branch.<name>.merge` give with b
  for `<name>`; `local` for the ref whose name is
  `refs/heads/` followed by b; and `remote` for the ref whose name is
  `refs/remotes/origin/` followed by b. No ref of the three exists other
  than those that the members name.
- `result`: no vector of the group has this member.
- `values`: when the default branch has a commit, a JSON object with one
  member, `commit`: that commit. When it has none, the empty JSON
  object, `{}`.

When a conforming program gives a commit as the commit of the default
branch under the binding, it gives the commit that `commit` holds. When
`values` is `{}`, it gives no commit as the commit of the default
branch.

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

When a conforming program gives a commit as the head commit of the
working tree, it gives the commit that `commit` holds. When `values` is
`{}`, it gives no commit as the head commit of the working tree.

```
{"group":"head-commits","input":{"head":{"ref":"refs/remotes/origin/main"},"refs":{"refs/remotes/origin/main":"e"}},"n":137,"note":"HEAD can name a ref that is not a branch","rev":"v1","values":{"commit":"e"}}
```

### 6.4 The files of the tree of a commit

The group `commit-files` holds the vectors of the requirement
`give-commit-files`. Each vector gives the git tree object of a commit
and the valid paths of the files of the tree of the commit.

- `input`: a JSON object with one member, `entries`: a JSON array with
  one JSON object for each entry that the git tree object of the commit
  lists, in the order in which it lists them. The JSON object of an
  entry has the member `name`, the name of the entry, a byte sequence,
  and the member `mode`, the characters of the mode of the entry, as the
  git tree object holds them, as a text, such as `100644` or `40000`. The JSON object of a tree entry also has
  the member `entries`, in the same form, for the entries that the git
  tree object that it names lists. A regular-file entry and a
  symbolic-link entry name blobs, and a submodule entry names a commit;
  the vectors do not give their contents.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `paths`: the set of the valid
  paths of the files of the tree of the commit.

When a conforming program gives the files of the tree of the commit, it
gives one file for each element of `paths`, with that valid path, and no
other file. The content of each file is the content of the blob of its
entry, which the vectors do not give.

```
{"group":"commit-files","input":{"entries":[{"mode":"100644","name":"a/b"},{"entries":[{"mode":"100644","name":"c"}],"mode":"40000","name":"a"}]},"n":140,"note":"a name that holds `/` gives no entry","rev":"v1","values":{"paths":["a/c"]}}
```

### 6.5 The files of the tree of a working tree

The group `working-tree-files` holds the vectors of the requirement
`give-working-tree-files`. Each vector gives the files of a folder tree,
the paths that git's index holds, the paths that are ignored, and the
valid paths of the files of the tree of the working tree.

- `input`: a JSON object with three members. `files` is a JSON array
  with one JSON object for each file of the folder tree whose root is
  the root folder of the working tree, other than the root and other
  than the files inside a folder whose entry name is `.git`, which the
  array can leave out. The JSON object has two members: `path`, the
  entry names of the folder entries from the root to the file, in
  order, with the byte 0x2F between each two of them, as a byte
  sequence; and `kind`, the kind of the file, one of the texts `regular`
  for a regular file, `folder` for a folder, `symbolic link` for a
  symbolic link, and `other` for a file of another kind. `tracked` is a
  JSON array of the valid paths whose UTF-8 encodings are the paths of
  the entries of git's index. `ignored` is a JSON array of the valid
  paths of the regular files of `files` that are ignored in the working
  tree. It can hold a path that `tracked` also holds.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `paths`: the set of the valid
  paths of the files of the tree of the working tree.

When a conforming program gives the files of the tree of the working
tree, it gives one file for each element of `paths`, with that valid
path, and no other file. The content of each file is the content of its
regular file, which the vectors do not give.

```
{"group":"working-tree-files","input":{"files":[{"kind":"folder","path":".jj"},{"kind":"folder","path":".jj/repo"},{"kind":"regular","path":".jj/repo/store"},{"kind":"regular","path":"a.md"}],"ignored":[],"tracked":["a.md"]},"n":101,"note":"a colocated jj repository","rev":"v1","values":{"paths":["a.md"]}}
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
  names the commit, and `false` when it does not. Its member `graft` is
  there when a line of the file `info/grafts` gives the commit other
  parents, and then it is these parents, as a sequence.
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

When a conforming program gives a commit as the commit of the ref, it
gives the commit that `commit` holds. When `values` is `{}`, it gives no
commit as the commit of the ref.

```
{"group":"ref-commits","input":{"ref":"refs/heads/dangling","refs":{"refs/heads/alias":{"ref":"refs/heads/main"},"refs/heads/alias2":{"ref":"refs/heads/alias"},"refs/heads/dangling":{"ref":"refs/heads/gone"},"refs/heads/main":{"commit":"c"},"refs/tags/v1":{"other":"t"}}},"n":169,"note":"a symbolic ref that names a ref that does not exist","rev":"v1","values":{}}
```

### 6.9 Ranges

The group `ranges` holds the vectors of the requirements `give-ranges`
and `give-parents-first-orders`. Each vector gives a commit graph, two
commits or one, and the commits of a range in their parents-first
order.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `to` is the commit h, and its member `from` is the commit s. The
  range is the range from s to h, or, when the object has no member
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

### 6.10 Changes and their bases

The group `changes` holds the vectors of the requirements
`give-changes`, `give-merge-bases`, and `give-change-bases`. Each vector
gives a commit graph, the commit of the default branch, and a commit h;
the commits of the change of h; the merge bases of h and the commit of
the default branch; and the base of the change of h, when it has one.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `last` is the commit h, and its member `default` is the commit
  of the default branch.
- `result`: no vector of the group has this member.
- `values`: a JSON object. Its member `change` is the set of the commits
  of the change of h, as a set of texts. Its member `merge-bases` is the
  set of the merge bases of h and the commit of the default branch, as a
  set of texts. Its member `base` is there when, and only when, the
  change of h has a base, and then it is that base.

When a conforming program gives the commits of the change of h, it
gives each element of `change`, and no other commit. When it gives the
merge bases of the two commits, it gives each element of `merge-bases`,
and no other commit. When it gives a commit as the base of the change of
h, it gives the commit that `base` holds. When `values` has no member
`base`, it gives no commit as the base of the change of h.

```
{"group":"changes","input":{"commits":{"a":[],"b":["a"],"c":["a"],"m1":["b","c"],"m2":["c","b"]},"default":"m2","last":"m1"},"n":69,"note":"merges that cross: two merge bases, so no base","rev":"v1","values":{"change":["m1"],"merge-bases":["b","c"]}}
```

### 6.11 First-parent lines and merge commits

The group `merge-commits` holds the vectors of the requirements
`give-first-parent-lines` and `give-merge-commits`. Each vector gives a
commit graph, two commits d and c, the first-parent line of d, and the
merge commit of c on that first-parent line, when there is one.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `line-of` is the commit d, and its member `commit` is the
  commit c.
- `result`: no vector of the group has this member.
- `values`: a JSON object. Its member `first-parent-line` is the
  first-parent line of d, as a sequence. Its member `merge-commit` is
  there when, and only when, d reaches c, and then it is the merge
  commit of c on the first-parent line of d.

When a conforming program gives the first-parent line of d, it gives the
elements of `first-parent-line`, in their order, and no other commit.
When it gives a commit as the merge commit of c on the first-parent line
of d, it gives the commit that `merge-commit` holds. When `values` has
no member `merge-commit`, it gives no commit as that merge commit.

```
{"group":"merge-commits","input":{"commit":"d","commits":{"a":[],"b":["a"],"c":["b"],"d":["b"],"e":["d"],"f":["c","e"],"g":["f"]},"line-of":"g"},"n":72,"note":"the merge commit `f` brought `d` to the first-parent line of `g`","rev":"v1","values":{"first-parent-line":["g","f","c","b","a"],"merge-commit":"f"}}
```

### 6.12 Hunks and the line map

The group `hunks` holds the vectors of the requirements `give-hunks` and
`give-new-line-numbers`. Each vector gives the content of the file with
the valid path `f` in an old tree and in a new tree, the hunks of `f`
between the two trees, and the line map of `f` between them.

- `input`: a JSON object. Its member `old` is the content of the file of
  the old tree whose valid path is `f`, a byte sequence. It is there
  when, and only when, the old tree has such a file. Its member `new` is
  the same for the new tree.
- `result`: no vector of the group has this member.
- `values`: a JSON object with two members. `hunks` is a JSON array of
  the hunks of `f` between the old tree and the new tree, in increasing
  order of their old starts. Each hunk is a JSON object with four
  members, each a whole number: `old-start`, its old start; `removed`,
  the number of the lines that it removes; `new-start`, its new start;
  and `added`, the number of the lines that it adds. `map` is a JSON
  array of the pairs of the line map of `f` between the old tree and the
  new tree, in increasing order of their first numbers. Each pair (i, j)
  is a JSON array of two whole numbers, i and then j.

When a conforming program gives the hunks of `f` between the two trees,
it gives one hunk for each element of `hunks`, with its four numbers,
and no other hunk. When it gives a line number in the new tree for the
line with the line number i of the text of the content of the file of
the old tree, it gives j for the element of `map` whose first number is
i. When no element of `map` has the first number i, it gives no line
number in the new tree for that line.

```
{"group":"hunks","input":{"new":"one\n2\nthree\nfour\n","old":"one\ntwo\nthree\n"},"n":108,"note":"the example of section 2.7","rev":"v1","values":{"hunks":[{"added":1,"new-start":2,"old-start":2,"removed":1},{"added":1,"new-start":4,"old-start":4,"removed":0}],"map":[[1,1],[3,3]]}}
```

### 6.13 The diffs of changes

The group `change-diffs` holds the vectors of the requirement
`give-change-diffs`. Each vector gives a commit graph, the tree of each
commit, the commit of the default branch, and a commit h, and the diff
of the change of h, when the change has a base.

- `input`: a JSON object. Its member `commits` is the commit graph. Its
  member `trees` is a JSON object with one member for each commit of the
  commit graph: its key is the name of the commit, and its value is the
  tree of the commit, as a tree. Its member `last` is the commit h, and
  its member `default` is the commit of the default branch.
- `result`: no vector of the group has this member.
- `values`: when the change of h has a base, a JSON object with one
  member, `diff`: a JSON array with one JSON object for each valid path
  that has one hunk or more in the diff of the change, in code point
  order of the valid paths. That JSON object has two members: `path`,
  the valid path, and `hunks`, its hunks, in the form of the member
  `hunks` of the group `hunks`. Each other valid path has no hunk in the
  diff. When the change of h has no base, the empty JSON object, `{}`.

When a conforming program gives the diff of the change of h, it gives,
for each element of `diff`, one hunk for each element of its `hunks`,
with its four numbers and with the valid path of `path`, and no other
hunk. When `values` is `{}`, it gives no diff of the change of h.

```
{"group":"change-diffs","input":{"commits":{"a":[],"b":["a"],"c":["a"],"m1":["b","c"],"m2":["c","b"]},"default":"m2","last":"m1","trees":{"a":{},"b":{"b.md":"b\n"},"c":{"c.md":"c\n"},"m1":{},"m2":{}}},"n":148,"note":"the change has no base, so it has no diff","rev":"v1","values":{}}
```
