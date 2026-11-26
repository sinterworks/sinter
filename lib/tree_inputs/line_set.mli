(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** Sets of file lines of one read file, each file line given by its number, as
    {!Tree_file.line} numbers them, and an index of such sets that gives the
    sets that have a thing and the innermost of them, as the term
    [innermost-item] of the design [documents=v1] defines it.

    A thing is in a set of file lines when each of its file lines is a line of
    that set. So a thing with no file line is in every set. *)

type t
(** A finite set of whole numbers.

    In this module, the runs of a set are its longest sequences of consecutive
    numbers: a set of the numbers from 1 to 1,000 has one run, and the set of 1,
    3, and 5 has three. The costs are given in the numbers of runs. *)

val empty : t
(** [empty] is the set with no element. *)

val of_list : int list -> t
(** [of_list numbers] is the set of the elements of [numbers]. The time grows as
    n log n in the length n of [numbers]. *)

val range : int -> int -> t
(** [range first last] is the set of the numbers from [first] to [last], or
    {!empty} when [last < first]. The time is constant. *)

val elements : t -> int list
(** [elements set] is the elements of [set], each once, in increasing order. The
    time is linear in the number of the elements. *)

val last : t -> int option
(** [last set] is the greatest element of [set], or [None] when [set] is empty.
    The time is constant. *)

val union : t list -> t
(** [union sets] is the set of the numbers that are elements of one or more of
    the sets of [sets]. The time grows as r log r in the number r of the runs of
    these sets. *)

val diff : t -> t -> t
(** [diff a b] is the set of the elements of [a] that are not elements of [b].
    The time is linear in the numbers of the runs of [a] and [b]. *)

(** An index of sets of file lines, each with a value of the caller.

    In this module, the distinct sets of an index are its sets with equal sets
    counted once, and R is the number of the runs of the distinct sets. *)
module Index : sig
  type set := t

  type 'a t
  (** A finite sequence of pairs, each a value and a set of file lines. *)

  val make : ('a * set) list -> 'a t
  (** [make pairs] is the index of [pairs]. The time grows as m log m times the
      number of the runs of the largest set, in the length m of [pairs], and as
      R log R. The memory is linear in m and R. *)

  val holders : 'a t -> set -> 'a list
  (** [holders index thing] is the values of the pairs of [index] whose sets
      have each element of [thing], in the order of the pairs. When [thing] is
      empty, it is the values of all the pairs. Let k be the number of the
      distinct sets that have the least element of [thing]. The time grows as (k
      \+ 1) log R, as k times the number of the runs of [thing] and of these
      sets, and as the number of the holders times its logarithm. *)

  val innermost : 'a t -> set -> 'a option
  (** [innermost index thing] is the value of the innermost pair, by their sets,
      of the pairs of {!holders}[ index thing]: the one pair whose set is a
      subset of the set of each of the others, when exactly one pair is such a
      pair. It is [None] when no pair is such a pair, or when two or more are,
      as two pairs with equal sets are. The time is that of {!holders}: it grows
      with the number of the distinct sets that have the least element of
      [thing], also when only one of them is the result. Sets that do not nest
      can cross, so each of these sets is checked. So n calls on things that n
      nested sets have take a time that grows as n^2. *)

  val subsets : 'a t -> ('a * 'a list) list
  (** [subsets index] is, for each pair of [index], in their order, its value
      and the values of the other pairs whose sets are subsets of its set, in
      the order of the pairs. The time is that of {!holders} for each distinct
      set, and grows as the length of each list times its logarithm. *)
end
