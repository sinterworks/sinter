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
    part of the folder tree that the system refuses or cannot give, by a refused
    permission, an input or output error, or a call that the system or a file
    system does not support, as {!Sinter_file_read.Walk.read} names these
    errors, is a missing part: the folder entries of a folder, or the content of
    a regular file. A function gives no value that needs a missing part and
    names each such part by its entry names from the root. A function whose walk
    stops at a limit of the program's own, or fails in another way, gives the
    {!Sinter_file_read.failure} of that walk and no value. *)

type t
(** A pack: its root and its folder tree, as one walk found it. *)

type failure =
  | Unread of string list list
      (** The walk could not take these parts, because the system refused a
          permission, reported an input or output error, or does not support a
          call that the walk needs. Each part is the entry names from the root
          of a folder whose folder entries, or of a regular file whose content,
          the walk could not take. Each part comes once, in the order of the
          walk. *)
  | Not_read of Sinter_file_read.failure
      (** the walk stopped at a limit of the program's own, failed, or found a
          change *)
  | Changed
      (** the second walk of {!listing} found other files than {!files} gives *)

val read : root:string -> (t, failure) result
(** [read ~root] is the pack whose root is the folder at the pathname [root]. It
    walks the whole folder tree once, with {!Sinter_file_read.walk}, and takes
    no byte of a regular file. It is [Error (Unread [ [] ])] when the walk could
    not take the folder entries of the root, and [Error (Not_read f)] when the
    walk gave [Error f]: then it gives no pack, so no result of a later use of
    the pack can come from a part of the folder tree. A folder tree with other
    unread folders gives a pack. *)

type content_failure =
  | No_file
      (** the pack has no file with the valid path, by the folder tree that
          {!read} found; also when {!Sinter_file_read.content} then gives
          [No_content_file], [Content_symbolic_link], or [Not_regular], such as
          for a file that changed after {!read} *)
  | Unreadable_file of string list
      (** The content needs this part, and the program could not take it: the
          entry names of an unread folder of the path in the folder tree that
          {!read} found, or of the folder or the file that
          {!Sinter_file_read.content} gives with [Cannot_take]. *)
  | Content_not_read of Sinter_file_read.failure
      (** {!Sinter_file_read.content} gave [Error] *)

val content : t -> Sinter_paths.Path.t -> (string, content_failure) result
(** [content pack path] is the content of the file of [pack] with the valid path
    [path], as a byte sequence, which need not be valid UTF-8. It is
    [Error No_file] when [pack] has no file with that valid path, by the folder
    tree that {!read} found, also when the last file name names an unread
    folder, and then it takes no byte. It is [Error (Unreadable_file names)]
    when a file name before the last one names an unread folder, and then it
    takes no byte. An unread folder off the path does not change the result. *)

val well_named_files :
  'a Sinter_file_read.Tree.entry list ->
  (Sinter_paths.Path.t list option, string list list) result
(** [well_named_files entries] is [Ok (Some paths)] with the valid paths of the
    files of the pack whose folder tree has a root with the folder entries
    [entries], in code point order, when that pack is well named, and [Ok None]
    when it is not. The files of that pack are its regular files, and an
    [Unread_file] counts as a regular file. A pack is well named when, and only
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
    below them are no paths of the pack.

    When the tree holds an [Unread_folder], the result is [Ok None] when the
    pack is not well named with each unread folder taken as empty, because no
    content of those folders can make it well named. Otherwise the result is
    [Error parts], with the entry names from the root of each [Unread_folder],
    each once, in the order of the walk. The function depends only on the names
    and the kinds of the entries; it calls no function of the system. Its time
    grows no faster than [n log n] with the number [n] of folder entries of the
    folder tree. *)

type well_named
(** A pack that is well named. *)

val well_named : t -> (well_named option, string list list) result
(** [well_named pack] is [Ok (Some named)] when [pack] is well named, [Ok None]
    when it is not, and [Error parts] when the result depends on unread folders,
    as {!well_named_files} decides it for the folder tree that {!read} found. It
    takes no byte from a file. *)

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
    [Error (Unread parts)] with each [Unread_folder] and each [Unread_file] of
    that walk, each once, in the order of the walk; [Error (Not_read f)] when
    that walk gives [Error f]; and [Error Changed] when it finds other files
    than {!files} gives. Then it gives no listing and no hash. *)

val listing_text : listing -> string
(** [listing_text listing] is the UTF-8 encoding of the pack listing: for each
    file of the pack, in the code point order of their valid paths, the hash of
    its content as 64 lower-case hex digits, two spaces, its valid path, and a
    line feed. *)

val hash : listing -> Sinter_hashes.Hash.t
(** [hash listing] is the pack hash: the hash of {!listing_text}[ listing]. *)
