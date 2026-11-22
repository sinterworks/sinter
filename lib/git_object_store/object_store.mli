(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The git objects that a git repository holds, read from the files of its
    object databases, as the term [commit] of the design [changes=v1] defines
    them: loose objects, as the page gitformat-loose defines them, and objects
    in packs of the versions 2 and 3 through pack indexes of the versions 1 and
    2, as the page gitformat-pack defines them, with both kinds of delta.

    The object databases of a git repository are the folder [objects] of its git
    folder and each folder that a file [info/alternates] of an object database
    names, in turn. Such a file, up to its first byte 0x00, is a sequence of
    entries, each from the end of the one before it. An entry that starts with
    [#] is a comment, up to the next byte 0x0A or the end, and names no
    pathname. An entry that starts with a double quote, then a C-quoted byte
    sequence, then a double quote, names that byte sequence, and the byte after
    the closing double quote, when there is one, is the end of the entry. Each
    other entry, a double quote with no valid end included, names its bytes up
    to the next byte 0x0A, and that byte 0x0A, or the end of the file, is the
    end of the entry. A C-quoted byte sequence holds any byte except a double
    quote and [\ ]; [\ ] and one of [\ ], a double quote, [a], [b], [f], [n],
    [r], [t], and [v] stand for 0x5C, 0x22, 0x07, 0x08, 0x0C, 0x0A, 0x0D, 0x09,
    and 0x0B; and [\ ], a digit [0] to [3], and two digits [0] to [7] stand for
    the byte of that octal number. The pathname of an entry ends before its
    first byte 0x00. An empty pathname names no object database. A pathname that
    does not start with [/] is relative to the folder of the object database
    that holds the file. A pathname that names no folder names no object
    database. Two pathnames of one folder, by
    {!Sinter_repository_files.READER.folder_identity}, are one object database.

    The pathnames that the store reads are these, made by the joining of byte
    sequences with no other change, where [<database>] is the pathname of an
    object database: [<git_folder>/objects] for the folder [objects] of the git
    folder at the pathname [<git_folder>]; [<database>/<p>] for a pathname [p]
    of an entry of the file [<database>/info/alternates] that does not start
    with [/], and [p] itself when it starts with [/]; and
    [<database>/<h>/<rest>], [<database>/pack], [<database>/pack/<name>.idx],
    and [<database>/pack/<name>.pack] below. Each damage and each failure names
    its file by such a pathname.

    The places of an object id X are these, in this order: for each object
    database, in the order of the object databases, the file of the loose object
    X, at the pathname [<database>/<h>/<rest>], where [<h>] is the first two hex
    digits of X and [<rest>] the other hex digits; then each pack of the
    database whose index lists X, once for each pack, in the order of the names
    of the indexes by {!String.compare}. A pack of a database is a file
    [pack/<name>.idx] of the database, its index, whose name starts with
    [pack-], with a file [pack/<name>.pack] beside it in the listing of the
    folder [pack]. The order of the object databases is the folder [objects] of
    the git folder first, then the object databases that each object database
    names, in the order of the object databases and of the entries, each at its
    first place.

    A place gives the object X when its bytes are in the form of the page for
    that place and the object that they give hashes to X: the SHA-1 or SHA-256
    hash, by the object format, of the type of the object, the byte 0x20, its
    size in decimal, the byte 0x00, and its content. A delta in a pack names its
    base by an offset in the same pack or by an object id. A base that an object
    id names is the entry that the index of the same pack lists under that id,
    and the object that it gives must hash to that id; when the index of the
    same pack does not list the id, the place gives nothing, also when another
    place holds the object of the id. *)

(** The type of a git object. *)
type kind =
  | Commit  (** a commit object, of the type [commit] *)
  | Tree  (** a git tree object, of the type [tree] *)
  | Blob  (** a blob, of the type [blob] *)
  | Tag  (** a tag object, of the type [tag] *)

type obj = {
  kind : kind;  (** the type of the object *)
  content : string;  (** the content of the object, byte for byte *)
}
(** A git object. *)

type limits = {
  max_content_size : int;
      (** the maximum size in bytes of the content of an object, of a base, and
          of the delta data of a delta; a number above {!Sys.max_string_length}
          acts as {!Sys.max_string_length} *)
  max_deltas : int;
      (** the maximum number of delta entries of packs that one lookup follows
          to their bases, over all the places that it tries *)
  max_databases : int;
      (** the maximum number of object databases, the folder [objects] of the
          git folder included *)
  max_packs : int;  (** the maximum number of packs in one object database *)
  max_alternates_size : int;
      (** the maximum size in bytes of one file [info/alternates] *)
}
(** The limits of the reads. *)

(** Why a place gives nothing. *)
type problem =
  | Not_zlib
      (** the compressed bytes are not one zlib stream of RFC 1950 that ends
          before the end of the data of the file, or the stream has a preset
          dictionary, or its Adler-32 checksum is not that of its bytes *)
  | Size_differs
      (** the stream inflates to more or fewer bytes than the size that the
          header states *)
  | Bytes_after_stream
      (** the file of a loose object holds bytes after the end of its zlib
          stream *)
  | Malformed_loose_header
      (** the inflated bytes of a loose object do not start with [blob], [tree],
          [commit], or [tag], the byte 0x20, the size in decimal digits with no
          leading digit [0] other than the size [0] itself, and the byte 0x00,
          with at most 32 bytes before that byte 0x00 *)
  | Malformed_entry_header
      (** the header of an entry of a pack has the type 0 or 5, or its size or
          its base offset is not complete before the end of the data of the
          pack, or its base offset does not lead to a place after the header of
          the pack and before the entry *)
  | Malformed_delta of Delta.error
      (** {!Delta.apply} gave this error, other than [Too_large] *)
  | Malformed_index
      (** the index is not in the form of the version 1 or 2: its size, its
          first bytes, a fan-out entry that is less than the one before it, or a
          last fan-out entry that is not the number of its objects; or an offset
          that it gives is not after the header of the pack and before its
          trailer; or the search for X read two names of the index that are not
          in the order of the index *)
  | Pack_does_not_match_index
      (** the pack does not start with [PACK] and the version 2 or 3, or its
          number of objects is not that of its index, or its last bytes are not
          the copy of them that the index holds *)
  | Wrong_id  (** the place gives an object that does not hash to X *)
  | Base_not_in_pack of Sinter_git_objects.Object_id.t
      (** the base of a delta of the place is named by this object id, and the
          index of the pack does not list it *)
  | Delta_cycle
      (** the bases of the deltas of the place lead, in turn, back to an entry
          that the place already followed *)

type damage = {
  pathname : string;
      (** the pathname of the file: the file of the loose object, the pack of
          the entry, or the index *)
  offset : int option;
      (** the offset of the entry in the pack from the start of the pack, for a
          problem of an entry; [None] for a problem of a loose object, of an
          index, or of the whole pack *)
  problem : problem;  (** the problem *)
}
(** A place that gives nothing, because it is not in its form or does not give
    the object of its id. *)

(* @satisfies text#report-stops-at-limits=v1
   A size above the limit gives [Too_large] with the pathname of the file, and
   with the offset of the entry for a packed entry or [None] for a loose
   object; a file [info/alternates] above its limit gives [Unread] with its
   pathname and the failure [Too_large]; and more packs than the limit give
   [Too_many_packs] with the pathname of the folder. So the report names the
   limit and where the lookup reached it. *)
type failure =
  | Unread of { pathname : string; failure : Sinter_repository_files.failure }
      (** a read of the file at [pathname] failed with [failure]. [No_file] at
          the pathname of a loose object, of an index, of a file
          [info/alternates], of a folder of an object database, or of a folder
          [pack] is no failure: no such file is there. [Not_a_folder] at the
          pathname of a folder of an object database or of a folder [pack] is no
          failure either: that pathname names no folder, which holds nothing.
          Each other failure, at any pathname, is [Unread]. *)
  | Too_large of { pathname : string; offset : int option }
      (** a header or delta data at this place states a size above
          [max_content_size] *)
  | Too_many_deltas
      (** the lookup would follow more than [max_deltas] delta entries *)
  | Too_many_databases
      (** the lookup would reach more than [max_databases] object databases *)
  | Too_many_packs of string
      (** the folder [pack] at this pathname holds more than [max_packs] packs
      *)

type lookup = {
  held : obj option;
      (** [Some obj] when a place gives the object; [None] when no place of an
          object database gives it *)
  damage : damage list;
      (** each place that the lookup tried and that gave nothing for a
          {!problem}, in the order in which the lookup tried them; when [held]
          is [Some _], the places before the one that gave the object *)
}
(** The result of a lookup. *)

(** The object store on the reads of a reader of repository files. *)
module Make (_ : Sinter_repository_files.READER) : sig
  type t
  (** The object store of a git repository. A value reads each file
      [info/alternates], the identity of each folder of an object database, the
      listing of each folder [pack], and the first and last bytes of each index
      and pack at the first lookup that needs it, and again at a later lookup
      only when that read failed. After [Too_many_packs] or
      [Too_many_databases], a later lookup that needs that folder [pack] or a
      database after that limit gives the same failure, with no read. It keeps
      what it read for as long as it lives: one value is for one repository
      read. It keeps for each object database its pathname and identity, and for
      each pack its pathnames and 256 numbers of its index. *)

  val create :
    limits -> Sinter_git_objects.Object_id.format -> git_folder:string -> t
  (** [create limits format ~git_folder] is the object store of the git
      repository whose git folder is at the pathname [git_folder], with object
      ids in the object format [format]. It reads no file. It raises
      [Invalid_argument] when a limit is negative. *)

  val find : t -> Sinter_git_objects.Object_id.t -> (lookup, failure) result
  (** [find store id] is the git object [id] that the git repository holds, from
      the first of its places, in their order, that gives it, and each place
      before it that gave nothing.

      It gives [Error], and no object and no damage, when a read fails or a
      limit stops the lookup. It stops at a header that states a size above
      [max_content_size] before it inflates the bytes after the header, and it
      never takes memory for more bytes of an object than its header states.

      It reads only these files: the files of the places, the files
      [info/alternates], the folders of the object databases and their folders
      [pack]. It reads no ref, no file [info/grafts] or [info/http-alternates],
      no multi-pack index, bitmap, reverse index, or commit-graph file, and no
      environment variable; it takes no object from another repository, a
      remote, or the network.

      Damage: the store does not check the checksum of a whole index or pack,
      the CRC32 values of an index, or the order of the names of an index other
      than those that a search reads. So an index whose names are not in order
      can make the lookup of an id that it lists give no place of that pack,
      with no damage. A place that is damaged in another way gives nothing, with
      its damage, and the lookup goes on to the next place.

      Cost, where h is the length in bytes of an object id of the object format
      (20 or 32): for each object database that the lookup reaches, one open of
      the file of the loose object; for each pack, at the first lookup that
      needs it, one open of the index with a read of its first 1032 bytes and a
      read of h bytes, and one open of the pack with a read of its first 12
      bytes and a read of its last h bytes; and for each pack, one open of the
      index and at most 3 + log2 n reads of it, where n is the number of objects
      of the index; for each entry of a pack that it follows, one read of 64
      bytes, or of the bytes before the last h bytes of the pack when they are
      fewer, for each 64 bytes of its header, and one read of h bytes for the
      object id of a delta entry that names its base by an object id; for each
      such delta entry, one search of the index of its pack, as above; the
      inflation of each base and of the delta data of each delta once for each
      place that it tries; and one hash over the object that each place gives
      and over each base that an object id names. One inflation reads its zlib
      stream from its first byte on: 4096 bytes, then each time twice as many
      bytes as the time before, and at most 65536 bytes, and never a byte of the
      last h bytes of a pack or after the end of the file of a loose object; so
      it reads at most twice the bytes of its zlib stream and 4096 bytes more.
      One lookup follows at most [max_deltas] delta entries, over all the places
      that it tries, and its damage holds at most
      [max_databases * (1 + max_packs)] items, one for each place. At one time
      it holds at most three contents of at most [max_content_size] bytes each,
      a base, delta data, and a result, and one record for each delta entry that
      it follows. The stack does not grow with the number of deltas or of object
      databases.

      It raises [Invalid_argument] when [id] is not in the object format of
      [store]. *)
end

include module type of Make (Sinter_repository_files)
(** The object store on the reads of the system of the process. *)
