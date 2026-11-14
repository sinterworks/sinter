(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The file read of the design [files=v1]: the reading of a text as a path in a
    folder tree.

    The root of the folder tree is given as a pathname of a folder. The system
    finds the root from that pathname, and it can follow a symbolic link on the
    way, because a file above the root is not a file of the folder tree. *)

type outcome =
  | Invalid  (** "invalid": the text is not a valid path *)
  | Found of Sinter_text.Text.t
      (** "found": the last file name names a regular file whose content is
          valid UTF-8; the text is the text of that whole content *)
  | No_file  (** "no file" *)
  | Symbolic_link  (** "symbolic link" *)
  | Not_a_regular_file  (** "not a regular file" *)
  | Not_utf_8  (** "not UTF-8" *)
  | Cannot_read  (** "cannot read" *)

type kind =
  | Folder  (** a folder: a file of the type directory *)
  | Regular_file  (** a regular file *)
  | Symbolic_link  (** a symbolic link itself, not a file that it leads to *)
  | Other_kind  (** a file of another kind, such as a pipe or a socket *)

(* @satisfies packs#read-only-pack-files=v1
   A folder tree holds, for each folder entry, only its entry name and its
   file, and for a symbolic link or a file of another kind no value at all, so
   a walk gives no byte of the reference of a symbolic link, of the data of a
   file of another kind, or of an extended attribute. *)

(** Folder trees as a walk finds them. *)
module Tree : sig
  (** A file of a folder tree, other than its root, with a value of type ['a]
      for each regular file. *)
  type 'a file =
    | Folder of 'a entry list
        (** a folder, with its folder entries, in increasing order of the bytes
            of their entry names *)
    | Regular_file of 'a  (** a regular file, with its value *)
    | Symbolic_link  (** a symbolic link itself, not a file that it leads to *)
    | Other_kind  (** a file of another kind, such as a pipe or a socket *)

  and 'a entry = { name : string; file : 'a file }
  (** A folder entry: its entry name, as a byte sequence, and its file. *)
end

(** Why a walk of a folder tree gives no tree. *)
type walk_failure =
  | Cannot_walk of string list
      (** A call of the system failed for the file at these entry names, from
          the root: the empty list for the root itself. *)

(** Why the bytes of a file are not given. *)
type content_failure =
  | Not_entry_names
      (** the sequence of entry names is empty, or one of its names is empty,
          holds [/] or U+0000, or is [.] or [..] *)
  | No_content_file
      (** a name is not in the listing of its folder, byte for byte, or a name
          before the last one names a file that is not a folder *)
  | Content_symbolic_link  (** a name names a symbolic link *)
  | Not_regular  (** the last name names a folder or a file of another kind *)
  | Cannot_take
      (** a call of the system failed, such as for lack of a permission *)

(* @satisfies packs#read-only-pack-files=v1
   No call of the system takes the reference of a symbolic link, the data of
   a file of another kind, or an extended attribute: the only bytes that the
   calls take are the names of the listing of a folder and the content of an
   open regular file. *)

(* @satisfies packs#gain-no-pack-privileges=v1
   No call of the system changes a user ID, a group ID, or a privilege of the
   process, or asks another process to act for it, and the walks and the file
   read make no call other than these. *)

(** The calls of the system that a file read makes. Each function, except
    [eilseq], raises [Unix.Unix_error] with the error that the system gives when
    the call fails; [content] can also raise [Sys_error]. *)
module type SYSTEM = sig
  type descr
  (** An open file: a folder, or the file that the last file name names. *)

  val open_root : string -> descr
  (** [open_root pathname] opens for reading the folder at [pathname]. The
      system can follow a symbolic link on the way. *)

  val open_folder : descr -> string -> descr
  (** [open_folder folder name] opens for reading the folder that the entry name
      [name] names in [folder]. It fails when that file is a symbolic link or
      not a folder. *)

  val open_file : descr -> string -> descr
  (** [open_file folder name] opens for reading the file that the entry name
      [name] names in [folder], and waits for no other process. It fails when
      that file is a symbolic link. *)

  val kind : descr -> string -> kind
  (** [kind folder name] is the kind of the file that the entry name [name]
      names in [folder]. *)

  val check_search : descr -> unit
  (** [check_search folder] returns when the process has the search permission
      for [folder]. *)

  val listing : descr -> string list
  (** [listing folder] is the names of the listing of [folder], in any order,
      [.] and [..] maybe among them. *)

  val is_regular_file : descr -> bool
  (** [is_regular_file file] is [true] when the open file [file] is a regular
      file. *)

  val content : descr -> string
  (** [content file] is the whole content of the open regular file [file]. *)

  val close : descr -> unit
  (** [close file] closes [file]. *)

  val eilseq : int
  (** The number of the error that the system gives, as [Unix.EUNKNOWNERR], when
      a file system does not accept a byte sequence as an entry name. *)
end

(** The file read on the calls of a system. *)
module Walk (_ : SYSTEM) : sig
  val read : root:string -> Sinter_text.Text.t -> outcome
  (** [read ~root text] is the file read of {!read}, made through the calls of
      the system. A text that is not a valid path gives [Invalid] with no call.
      When [kind] raises [Unix.Unix_error] with [ENOENT], [ENAMETOOLONG],
      [EINVAL], or [EUNKNOWNERR n] where [n] is [eilseq] of the system, the
      result is [No_file]. When [kind] raises another error, or another call
      other than [close] raises [Unix.Unix_error] or [Sys_error], the result is
      [Cannot_read]. Any other exception of a call goes through. When
      [is_regular_file] gives [false] for the last file once it is open, the
      result is [Not_a_regular_file]. It closes each descriptor that the system
      opens for it, also when a call raises, and it ignores an error of [close].
  *)

  val walk : root:string -> (unit Tree.entry list, walk_failure) result
  (** [walk ~root] is the folder entries of the root of the folder tree whose
      root is the folder at the pathname [root], each with its file, made
      through the calls of the system. The root opens with [open_root]; each
      other folder opens with [open_folder] relative to the folder that holds
      it; the kind of each file comes from [kind] before any open of that file;
      and only folders open, so the walk opens no regular file, no symbolic
      link, and no file of another kind. The names of a folder are those of
      [listing] other than [.] and [..].

      When a call other than [close] raises [Unix.Unix_error] or [Sys_error],
      the result is [Error (Cannot_walk names)], with the entry names, from the
      root, of the file of that call, and never a tree. This is also the result
      when the system has no file descriptor left for the next folder. Any other
      exception of a call goes through. At most one descriptor is open for each
      folder from the root to the folder that the walk is in. The walk closes
      each descriptor that the system opens for it before it returns or raises,
      and it ignores an error of [close]. Its use of the call stack does not
      grow with the depth of the folder tree. *)

  val walk_contents :
    root:string -> (string -> 'a) -> ('a Tree.entry list, walk_failure) result
  (** [walk_contents ~root value] is [walk ~root], except that each regular file
      has [value bytes], where [bytes] is its content. After [kind] gives
      [Regular_file] for a name, the walk opens that file with [open_file]
      relative to the folder that holds it, takes its content with [content]
      when [is_regular_file] gives [true], closes it, and then calls [value]:
      once for each regular file, in the order of the walk. In that order, the
      entries of a folder come in increasing order of the bytes of their names,
      and the entries of a folder come right after the entry of that folder.
      When [is_regular_file] gives [false], or a call raises [Unix.Unix_error]
      or [Sys_error], the result is [Error (Cannot_walk names)] for the names of
      that file. An exception of [value] goes through, and the walk still closes
      each descriptor. *)

  val content : root:string -> string list -> (string, content_failure) result
  (** [content ~root names] is the content of the regular file that the entry
      names [names] lead to from the root of the folder tree whose root is the
      folder at the pathname [root], made through the calls of the system, as a
      byte sequence that need not be valid UTF-8. It makes the same calls as
      [read] in the same order, for the names [names] in place of the UTF-8
      encodings of the file names of a valid path, and the cases of [read] give
      the failures: [No_file] gives [No_content_file], [Symbolic_link] gives
      [Content_symbolic_link], [Not_a_regular_file] gives [Not_regular], and
      [Cannot_read] gives [Cannot_take]. [Not_entry_names] comes with no call.
  *)
end

val read : root:string -> Sinter_text.Text.t -> outcome
(** [read ~root text] reads [text] as a path in the folder tree whose root is
    the folder at the pathname [root], and gives the result of that file read.
    It gives [Invalid] when [text] is not a valid path, whatever [root] is, and
    then takes no byte from a file. Otherwise it gives [Cannot_read] when the
    system cannot open [root] as a folder for reading, also when [root] holds
    U+0000 or names no folder. While no other process changes the folder tree,
    the result is the file-read result of the valid path, or [Cannot_read] when
    the system fails for a cause other than the folder tree and the permissions
    of the process. In each call, also when another process changes the folder
    tree, [read] follows no symbolic link of the folder tree, takes bytes only
    from the folders of the path and from the regular file that the last file
    name names, waits for no other process and no device, changes no file of the
    folder tree, and changes no user ID, group ID, or privilege of the process.
    It closes each file descriptor that it opens before it returns. It raises
    [Out_of_memory] when the content does not fit in memory. *)

val walk : root:string -> (unit Tree.entry list, walk_failure) result
(** [walk ~root] is the folder entries of the root of the folder tree whose root
    is the folder at the pathname [root], with the file of each, as {!Walk.walk}
    gives them with the calls of this system. When no other process changes the
    folder tree, the result is the folder entries of the folder tree, or [Error]
    when the system fails, such as for lack of a permission or of a file
    descriptor. [Error] carries no tree, so a caller gives no result from a walk
    that failed. In each call, also when another process changes the folder
    tree, [walk] follows no symbolic link of the folder tree, takes bytes only
    from its folders (the names of their listings), opens no file that is not a
    folder, waits for no other process and no device, changes no file of the
    folder tree, and changes no user ID, group ID, or privilege of the process.
    It closes each file descriptor that it opens before it returns. It raises
    [Out_of_memory] when the tree does not fit in memory. *)

val walk_contents :
  root:string -> (string -> 'a) -> ('a Tree.entry list, walk_failure) result
(** [walk_contents ~root value] is {!walk}[ ~root] with [value bytes] for each
    regular file, where [bytes] is its content, as {!Walk.walk_contents} gives
    it with the calls of this system. It keeps every promise of {!walk}, except
    that it also takes bytes from the regular files of the folder tree: each one
    opens for reading only, relative to the open folder that holds it, never
    through a symbolic link and never when it is not a regular file, and with no
    wait for another process. It lists each folder once and takes the content of
    each regular file once. It raises [Out_of_memory] when a content does not
    fit in memory. *)

val content : root:string -> string list -> (string, content_failure) result
(** [content ~root names] is the content of the regular file that the entry
    names [names] lead to from the folder at the pathname [root], as
    {!Walk.content} gives it with the calls of this system. In each call it
    keeps every promise of {!read} on the folder tree: it follows no symbolic
    link, takes bytes only from the folders of the names and from the regular
    file that the last name names, waits for no other process and no device,
    changes no file, changes no user ID, group ID, or privilege of the process,
    and closes each file descriptor that it opens before it returns. It raises
    [Out_of_memory] when the content does not fit in memory. *)
