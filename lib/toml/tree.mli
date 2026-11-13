(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The tables of a document while the reader reads it, and the rules of TOML
    1.1.0 on which key/value pair and which table header may add what to them.

    A table under construction holds keys, each with a node. The parts of the
    document act on the tables one after another, in the order of the document.
    A key/value pair walks the parts of its key, except the last, from its
    holding table, and then adds its last part with its value. A table header
    walks the parts of its key from the root table and then names a table. *)

type table
(** A table under construction. *)

type node
(** A value under construction. *)

type slot
(** The table and the key to which a key/value pair adds its value. *)

val root : unit -> table
(** [root ()] is a new, empty root table. *)

val inline : unit -> table
(** [inline ()] is a new, empty table of an inline table. *)

val scalar : Types.value -> node
(** [scalar value] is a node of [value], which is not an [Array] and not a
    [Table]. *)

val array : node list -> node
(** [array elements] is a node of an array that the document writes with
    brackets, with [elements] in their order. *)

val table_value : table -> node
(** [table_value table] is a node of the table of an inline table. *)

val walk_pair : table -> string -> string list -> (slot, Types.error) result
(** [walk_pair holding first rest] acts as a key/value pair whose key has the
    parts [first :: rest], as texts, and whose holding table is [holding], up to
    its value. For each part before the last:
    - when the table at which the walk stands does not hold the text, it makes a
      new table there, which the key/value pair defines;
    - when it holds the text with an array that table headers of an array of
      tables make, the walk goes on to the last table of that array;
    - when it holds a table, the walk goes on to that table, and the key/value
      pair defines that table when no table header named it and no other part
      defined it.

    It is [Ok slot] for the table where the walk ends and the last part. It is
    [Error Inline_table_closed] when the walk comes to the table of an inline
    table, [Error Dotted_key_into_named_table] when it comes to a table that a
    table header named, [Error Not_a_table] when it comes to another value, and
    [Error Duplicate_key] when the table where the walk ends holds the last
    part. A walk that gives an [Error] can have made tables already. *)

val fill : slot -> node -> unit
(** [fill slot node] adds the last part of [slot] to its table, with [node]. *)

val walk_header :
  table -> string -> string list -> array:bool -> (table, Types.error) result
(** [walk_header root first rest ~array] acts as a table header whose key has
    the parts [first :: rest], as texts, and is [Ok table] for the table that
    the header names. [array] is [true] for a header with double brackets. For
    each part before the last, the walk goes on as {!walk_pair} says, except
    that a new table is a super-table that no part defines, and that it gives
    [Error Not_a_table] for a value that is neither a table nor an array of
    tables that table headers make. Then for the last part:
    - Without double brackets, the header makes a new table when the table where
      the walk ends does not hold the part, and names it. When that table holds
      a super-table that no part defines, the header names it. It is
      [Error Table_defined_twice] for a table that a part defines, and for an
      array that table headers make, and [Error Not_a_table] for every other
      value.
    - With double brackets, the header makes a new array of one new table when
      the table where the walk ends does not hold the part, and adds a new table
      to the end of the array when it holds an array that table headers make; it
      names the new table. It is [Error Not_an_array_of_tables] for every other
      value.

    It is [Error Inline_table_closed] when the walk, the last part included,
    comes to the table of an inline table. *)

val freeze : table -> Types.table
(** [freeze root] is the table of [root], as it holds its keys now, with the
    pairs in the order in which the keys came to each table. The stack space
    that it uses does not grow with the depth of the tables. *)
