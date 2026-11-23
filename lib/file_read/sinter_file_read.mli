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
  | Cannot_read
      (** "cannot read": the report of a part that the folder tree lacks,
          because the system refused a permission or reported an input or output
          error *)

type kind =
  | Folder  (** a folder: a file of the type directory *)
  | Regular_file  (** a regular file *)
  | Symbolic_link  (** a symbolic link itself, not a file that it leads to *)
  | Other_kind  (** a file of another kind, such as a pipe or a socket *)

(** A limit of the program's own, at which a read or a walk stops. *)
type limit =
  | Descriptors  (** no free file descriptor: [EMFILE] or [ENFILE] *)
  | Memory  (** no memory: [ENOMEM], or [Out_of_memory] *)
  | File_size  (** a file too large to read whole: [EOVERFLOW] *)
  | Pathname_length
      (** the pathname of the root is too long: [ENAMETOOLONG] from [open_root]
      *)

(** Why a read, a content, or a walk gives no result. *)
type failure =
  | Stopped of { limit : limit; names : string list }
      (** The program stopped at this limit of its own, at the file of these
          entry names from the root: the empty list for the root itself. *)
  | Failed of { names : string list; error : Unix.error }
      (** A call of the system for the file of these entry names gave an error
          that no other case names. *)
  | Changed of string list
      (** The folder tree changed during a walk: [kind] gave [Regular_file] for
          the file of these entry names, and [is_regular_file] gave [false] once
          that file was open. *)

(* @satisfies packs#read-only-pack-files=v1
   A folder tree holds, for each folder entry, only its entry name and its
   file, and for a symbolic link or a file of another kind no value at all, so
   a walk gives no byte of the reference of a symbolic link, of the data of a
   file of another kind, or of an extended attribute. *)

(** Folder trees as a walk finds them. *)
module Tree : sig
  (** A file of a folder tree, with a value of type ['a] for each regular file
      whose content the walk took. *)
  type 'a file =
    | Folder of 'a entry list
        (** a folder, with its folder entries, in increasing order of the bytes
            of their entry names *)
    | Regular_file of 'a  (** a regular file, with its value *)
    | Symbolic_link  (** a symbolic link itself, not a file that it leads to *)
    | Other_kind  (** a file of another kind, such as a pipe or a socket *)
    | Unread_folder
        (** a folder whose folder entries, with the kinds of their files, the
            walk could not take, because the system refused a permission or
            reported an input or output error *)
    | Unread_file
        (** a regular file whose content {!Walk.walk_contents} could not take,
            for the same causes *)

  and 'a entry = { name : string; file : 'a file }
  (** A folder entry: its entry name, as a byte sequence, and its file. *)
end

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
  | Cannot_take of string list
      (** the system refused a permission or reported an input or output error
          for the folder or the file of these entry names (the empty list for
          the root), so the content is a missing part *)

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
    [eilseq] and [estale], raises [Unix.Unix_error] with the error that the
    system gives when the call fails. *)
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
  (** [close file] closes [file]. It raises no exception other than
      [Unix.Unix_error]. *)

  val eilseq : int
  (** The number of the error that the system gives, as [Unix.EUNKNOWNERR], when
      a file system does not accept a byte sequence as an entry name. *)

  val estale : int
  (** The number of the error [ESTALE] of the system, as [Unix.EUNKNOWNERR]: a
      file handle that is no longer valid, such as on a file system of another
      machine. *)
end

(** The file read on the calls of a system. *)
module Walk (_ : SYSTEM) : sig
  val read : root:string -> Sinter_text.Text.t -> (outcome, failure) result
  (** [read ~root text] is the file read of {!read}, made through the calls of
      the system. A text that is not a valid path gives [Ok Invalid] with no
      call. When [is_regular_file] gives [false] for the last file once it is
      open, the result is [Ok Not_a_regular_file]. It closes each descriptor
      that the system opens for it exactly once, also when a call raises, and it
      ignores an error of [close].

      When a call other than [close] raises [Unix.Unix_error] with an error [e],
      the result comes from the first of these cases that holds:

      + The call is [kind], and [e] is [ENOENT], [ENAMETOOLONG], [EINVAL], or
        [EUNKNOWNERR n] where [n] is [eilseq] of the system: [Ok No_file].
      + [e] is [EACCES] or [EPERM] (a refused permission), or [EIO], [ENXIO],
        [ENODEV], [ETIMEDOUT], [ECONNABORTED], [ECONNRESET], [ENOTCONN],
        [ENETDOWN], [ENETRESET], [ENETUNREACH], [EHOSTUNREACH], or
        [EUNKNOWNERR n] where [n] is [estale] of the system (an input or output
        error): [Ok Cannot_read].
      + [e] is [EMFILE] or [ENFILE]: [Error (Stopped)] with [Descriptors].
      + [e] is [ENOMEM]: [Error (Stopped)] with [Memory].
      + [e] is [EOVERFLOW]: [Error (Stopped)] with [File_size].
      + The call is [open_root], and [e] is [ENAMETOOLONG]: [Error (Stopped)]
        with [Pathname_length].
      + Otherwise, such as for [ENOENT] or [ENOTDIR] from [open_root], [ELOOP]
        from [open_folder], [EINTR], or [ENOSYS] or [EOPNOTSUPP] from any call:
        [Error (Failed)] with [e].

      When a call other than [close], or the decoding of the content as UTF-8,
      raises [Out_of_memory], the result is [Error (Stopped)] with [Memory].

      The names of [Stopped] and [Failed] are those of the file of the call: the
      folder for [check_search] and [listing], the file that the name names for
      [kind], [open_folder], and [open_file], and the open file for
      [is_regular_file] and [content]. Any other exception of a call, such as
      [Sys_error], goes through. *)

  val walk : root:string -> (unit Tree.file, failure) result
  (** [walk ~root] is the root of the folder tree whose root is the folder at
      the pathname [root], as a file, made through the calls of the system:
      [Folder entries] with the folder entries of the root, each with its file,
      or [Unread_folder]. The root opens with [open_root]; each other folder
      opens with [open_folder] relative to the folder that holds it; the kind of
      each file comes from [kind] before any open of that file; and only folders
      open, so the walk opens no regular file, no symbolic link, and no file of
      another kind. The names of a folder are those of [listing] other than [.]
      and [..].

      An error of the second case of {!read} makes a folder [Unread_folder] when
      [open_root] or [open_folder] for that folder, [listing] of that folder, or
      [kind] of one of its names raises it; the walk then keeps no entry of that
      folder and goes on with the rest of the tree. When [kind] raises an error
      of the first case of {!read}, the result is [Error (Failed)] with that
      error. Each error of the other cases of {!read} gives [Error] as {!read}
      gives it. In both cases the names are those of the file of the call, and
      the result holds no tree. [Out_of_memory] from a call other than [close]
      gives [Error (Stopped)] with [Memory], with the names of the file of the
      call. Any other exception of a call goes through. At most one descriptor
      is open for each folder from the root to the folder that the walk is in.
      The walk closes each descriptor that the system opens for it exactly once,
      before it returns or raises, and it ignores an error of [close]. Its use
      of the call stack does not grow with the depth of the folder tree. *)

  val walk_contents :
    root:string -> (string -> 'a) -> ('a Tree.file, failure) result
  (** [walk_contents ~root value] is [walk ~root], except that each regular file
      has [value bytes], where [bytes] is its content. After [kind] gives
      [Regular_file] for a name, the walk opens that file with [open_file]
      relative to the folder that holds it, takes its content with [content]
      when [is_regular_file] gives [true], closes it, and then calls [value]:
      once for each regular file, in the order of the walk. In that order, the
      entries of a folder come in increasing order of the bytes of their names,
      and the entries of a folder come right after the entry of that folder. An
      error of the second case of {!read} from [open_file], [is_regular_file],
      or [content] makes that file [Unread_file], and the walk goes on. When
      [is_regular_file] gives [false], the result is [Error (Changed names)]
      with the names of that file. Each other error gives [Error] as in [walk].
      An exception of [value], [Out_of_memory] included, goes through, and the
      walk still closes each descriptor exactly once. *)

  val content :
    root:string ->
    string list ->
    ((string, content_failure) result, failure) result
  (** [content ~root names] is the content of the regular file that the entry
      names [names] lead to from the root of the folder tree whose root is the
      folder at the pathname [root], made through the calls of the system, as a
      byte sequence that need not be valid UTF-8. It makes the same calls as
      [read] in the same order, for the names [names] in place of the UTF-8
      encodings of the file names of a valid path, and the cases of [read] give
      the failures: [No_file] gives [No_content_file], [Symbolic_link] gives
      [Content_symbolic_link], [Not_a_regular_file] gives [Not_regular],
      [Cannot_read] gives [Cannot_take] with the names of the file of the call
      (for [kind], the folder that holds the name), and [Error] gives [Error].
      [Not_entry_names] comes with no call. *)
end

val read : root:string -> Sinter_text.Text.t -> (outcome, failure) result
(** [read ~root text] reads [text] as a path in the folder tree whose root is
    the folder at the pathname [root], and gives the result of that file read,
    as {!Walk.read} gives it with the calls of this system. It gives
    [Ok Invalid] when [text] is not a valid path, whatever [root] is, and then
    takes no byte from a file. It gives [Error (Failed)] when [root] names no
    folder, also when [root] holds U+0000. While no other process changes the
    folder tree, the result is the file-read result of the valid path, or
    [Ok Cannot_read] when the system refuses a permission or reports an input or
    output error, or [Error] when the read stops at a limit of the program's
    own. A call that fails with [EINTR] runs again. When [faccessat] gives
    [ENOSYS], [EOPNOTSUPP], [EINVAL], or [ENOTSUP], the check of the search
    permission for a folder looks up [.] in that folder instead, which needs the
    same permission. In each call, also when another process changes the folder
    tree, [read] follows no symbolic link of the folder tree, takes bytes only
    from the folders of the path and from the regular file that the last file
    name names, waits for no other process and no device, changes no file of the
    folder tree, and changes no user ID, group ID, or privilege of the process.
    It closes each file descriptor that it opens exactly once, before it
    returns. *)

val walk : root:string -> (unit Tree.file, failure) result
(** [walk ~root] is the root of the folder tree whose root is the folder at the
    pathname [root], as a file, as {!Walk.walk} gives it with the calls of this
    system. When no other process changes the folder tree, the result is the
    root with the folder entries of the folder tree, with [Unread_folder] for
    each folder whose entries the system refused or could not give, or [Error]
    when the walk stops at a limit of the program's own or a call fails in
    another way. [Error] carries no tree, so a caller gives no result from a
    walk that failed. In each call, also when another process changes the folder
    tree, [walk] follows no symbolic link of the folder tree, takes bytes only
    from its folders (the names of their listings), opens no file that is not a
    folder, waits for no other process and no device, changes no file of the
    folder tree, and changes no user ID, group ID, or privilege of the process.
    It closes each file descriptor that it opens exactly once, before it
    returns. *)

val walk_contents :
  root:string -> (string -> 'a) -> ('a Tree.file, failure) result
(** [walk_contents ~root value] is {!walk}[ ~root] with [value bytes] for each
    regular file, where [bytes] is its content, as {!Walk.walk_contents} gives
    it with the calls of this system. It keeps every promise of {!walk}, except
    that it also takes bytes from the regular files of the folder tree: each one
    opens for reading only, relative to the open folder that holds it, never
    through a symbolic link and never when it is not a regular file, and with no
    wait for another process. It lists each folder once and takes the content of
    each regular file once. *)

val content :
  root:string ->
  string list ->
  ((string, content_failure) result, failure) result
(** [content ~root names] is the content of the regular file that the entry
    names [names] lead to from the folder at the pathname [root], as
    {!Walk.content} gives it with the calls of this system. In each call it
    keeps every promise of {!read} on the folder tree: it follows no symbolic
    link, takes bytes only from the folders of the names and from the regular
    file that the last name names, waits for no other process and no device,
    changes no file, changes no user ID, group ID, or privilege of the process,
    and closes each file descriptor that it opens exactly once, before it
    returns. *)
