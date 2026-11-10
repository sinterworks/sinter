(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The tag lines of a text, read under a binding of [external-namespaces], as
    the design [identifiers=v1] defines them.

    Each text here is the UTF-8 encoding of a run of the text of the tag line,
    with its case unchanged. *)

(* @satisfies identifiers#give-no-other-values=v1 *)

(** A valid tag line, with its values. *)
type tag =
  | Declaration of {
      word : Tag_word.t;
      slug : string;
      part_name : string option;
      revision : string option;
      inline_description : string;
    }
      (** A declaration. [word] is [@decision], [@design], [@finding-class],
          [@req], [@spec], or [@term]. [slug] is the slug of the target, or, for
          [@spec] with no [#], the segment of the target. [part_name] is the
          part name after the [#] of a full name. [revision] is the label; it is
          [None] only for [@term]. *)
  | Citation of {
      word : Tag_word.t;
      entries : Target.t list;
      inline_description : string;
    }
      (** A citation. [word] is [@cites], [@refines], [@satisfies],
          [@supersedes], or [@verifies]. [entries] is the values of each
          citation entry, in the order of the citation entries; it is never
          empty. *)
  | Status_tag of { word : Tag_word.t; inline_description : string }
      (** A status tag. [word] is [@deferred], [@deprecated], or [@rejected]. *)
  | Extern of {
      kind_word : Kind_word.t;
      part_name : string;
      inline_description : string;
    }  (** An [@extern] line, a directive. *)
  | Ack of { slug : string; subject : string; hash_prefix : string }
      (** An [@ack] line, a directive. [subject] is the empty text when the line
          has no subject. *)

(* @satisfies identifiers#give-no-other-values=v1 *)

(** The result of a line of a text, with the values that go with it. *)
type line_result =
  | Not_a_tag_line
      (** the first character of the line after its spaces and tabs is not [@]
      *)
  | Other_tag_word of string
      (** a tag line whose tag word, given here, is not a Sinter tag word *)
  | Invalid of Tag_word.t
      (** a tag line with this Sinter tag word that has no match *)
  | Valid of tag  (** a tag line with a match, and its values *)

type input = { first_line : int; last_line : int; result : line_result }
(** An input that the lines of a text make: a line, or a citation with its
    continuation lines. [first_line] and [last_line] are the line numbers of its
    first line and of its last line; they differ only for a citation with
    continuation lines. *)

val tag_word : tag -> Tag_word.t
(** [tag_word tag] is the tag word of [tag]. *)

(* @satisfies identifiers#use-one-binding=v1 *)
val read : Binding.t -> Sinter_text.Text.t -> input list
(** [read binding text] is the inputs that the lines of [text] make under
    [binding], in the order of their first lines. Each line of [text] is in
    exactly one input. The time is linear in the length of [text], except for
    the fit of each id to the id pattern of its external namespace. *)
