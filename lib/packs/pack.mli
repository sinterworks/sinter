(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Packs, as the design [packs=v1] defines them: a folder tree, its files,
    whether it is well named, and, for a well-named pack, its pack listing and
    its pack hash.

    A pack is the folder tree whose root is the folder at a pathname. A file of
    the pack is a valid path whose last file name names a regular file of the
    folder tree, by the UTF-8 encodings of its file names, with the content of
    that regular file. Each function takes bytes from the folder tree only
    through {!Sinter_file_read.walk}, {!Sinter_file_read.walk_contents}, and
    {!Sinter_file_read.content}. So, in each call, also when another process
    changes the folder tree, it follows no symbolic link of the folder tree,
    takes bytes only from its folders and its regular files, opens no file of
    another kind and waits for no other process and no device, changes no file
    of the folder tree, and changes no user ID, group ID, or privilege of the
    process.

    The results below hold while no other process changes the folder tree. A
    function that cannot take the bytes that it needs, such as for lack of a
    permission or of a file descriptor, gives [Error Unreadable], which carries
    no value. *)

type t
(** A pack: its root and its folder tree, as one walk found it. *)

type failure =
  | Unreadable
      (** a call of the system failed, such as for lack of a permission or of a
          file descriptor, or the folder tree changed during the use *)

val read : root:string -> (t, failure) result
(** [read ~root] is the pack whose root is the folder at the pathname [root]. It
    walks the whole folder tree once, and takes no byte of a regular file. It is
    [Error Unreadable] when the walk fails: then it gives no pack, so no result
    of a later use of the pack can come from a part of the folder tree. *)

type content_failure =
  | No_file  (** the pack has no file with the valid path *)
  | Unreadable_file  (** the bytes of the file could not be taken *)

val content : t -> Sinter_paths.Path.t -> (string, content_failure) result
(** [content pack path] is the content of the file of [pack] with the valid path
    [path], as a byte sequence, which need not be valid UTF-8. It is
    [Error No_file] when [pack] has no file with that valid path, by the folder
    tree that {!read} found, and then it takes no byte. *)

val well_named_files :
  'a Sinter_file_read.Tree.entry list -> Sinter_paths.Path.t list option
(** [well_named_files entries] is the valid paths of the files of the pack whose
    folder tree has a root with the folder entries [entries], in code point
    order, when that pack is well named, and [None] when it is not. The files of
    that pack are its regular files, and a pack is well named when, and only
    when, it meets each of these conditions:

    - The entry name of each folder entry whose file is a regular file, or a
      folder with a regular file somewhere below it, is the UTF-8 encoding of a
      file name.
    - Each path of the pack is a pack path. The paths of the pack are the valid
      paths of its files, and each part of one of them from its start to right
      before a [/].
    - No two different paths of the pack are the same text after ASCII case
      folding, which changes each letter from [A] to [Z] to the same letter from
      [a] to [z].

    Symbolic links, files of another kind, and folders with no regular file
    below them are no paths of the pack. The function depends only on the names
    and the kinds of the entries; it calls no function of the system. Its time
    grows no faster than [n log n] with the number [n] of folder entries of the
    folder tree. *)

type well_named
(** A pack that is well named. *)

val well_named : t -> well_named option
(** [well_named pack] is [Some] when [pack] is well named, and [None] when it is
    not, as {!well_named_files} decides it for the folder tree that {!read}
    found. It takes no byte from a file. *)

val pack : well_named -> t
(** [pack named] is the pack that is well named. *)

(* @satisfies packs#{omit-pack-listings=v1, omit-pack-hashes=v1}
   Only a well-named pack gives the files, the pack listing, and the pack hash
   below, so a pack that is not well named gives no pack listing and no pack
   hash. *)

val files : well_named -> Sinter_paths.Path.t list
(** [files named] is the valid paths of the files of [named], each once, in code
    point order, as {!well_named_files} gives them. It takes no byte from a
    file. *)

type listing
(** The pack listing of a well-named pack, with its pack hash. *)

val listing : well_named -> (listing, failure) result
(** [listing named] is the pack listing of [named]. It walks the folder tree of
    the pack once more: it lists each folder once, and it takes the content of
    each regular file once, through the folder that holds it. Its time grows
    linearly with the number of bytes of the contents, and no faster than
    [n log n] with the number [n] of folder entries of the folder tree. It is
    [Error Unreadable] when that walk fails, or when it finds other files than
    {!files} gives, and then it gives no listing and no hash. *)

val listing_text : listing -> string
(** [listing_text listing] is the UTF-8 encoding of the pack listing: for each
    file of the pack, in the code point order of their valid paths, the hash of
    its content as 64 lower-case hex digits, two spaces, its valid path, and a
    line feed. *)

val hash : listing -> Sinter_hashes.Hash.t
(** [hash listing] is the pack hash: the hash of {!listing_text}[ listing]. *)
