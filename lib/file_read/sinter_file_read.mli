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
