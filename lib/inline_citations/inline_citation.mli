(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The links and the images of the markdown document of a text, read under a
    binding of [external-namespaces], as the design [identifiers=v1] defines
    them.

    The markdown document of a text is the text of its body, with each U+0000
    replaced by U+FFFD. Its links and images are those of CommonMark 0.31.2, and
    an autolink in the link text of a link is a link too. *)

(* @satisfies identifiers#give-no-other-values=v1 *)

(** The result of a link or an image, with the values that go with it. *)
type link_result =
  | Not_an_inline_citation
      (** an image, or a link whose destination does not start with [sinter:] *)
  | Invalid
      (** an inline citation whose destination has no match, or whose link text
          has a plain string content of blank characters only *)
  | Valid of { target : Target.t; link_text : string }
      (** a valid inline citation. [target] is the values of its target; it is
          never [Target.Every_part], and its vector selection is [None].
          [link_text] is the UTF-8 encoding of its link text. *)

type link = { run : Sinter_text.Text.run; result : link_result }
(** A link or an image. [run] is the run of the text that it covers, from the
    boundary right before its first character to the boundary right after its
    last character. *)

(* @satisfies identifiers#use-one-binding=v1 *)
val read : Binding.t -> Sinter_text.Text.t -> link list
(** [read binding text] is the links and the images of the markdown document of
    [text] under [binding], in the order in which they start in the markdown
    document; a link in the link text of another link comes after that other
    link. *)
