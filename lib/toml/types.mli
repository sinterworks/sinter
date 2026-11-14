(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The types of the values, spans, and failures of {!Sinter_toml}, which
    documents them. *)

type span = { start : int; stop : int }
type key = { whole : span; parts : span list }
type date = { year : int; month : int; day : int }
type time = { hour : int; minute : int; second : int; nanosecond : int }
type offset = Minutes of int | Unknown_local

type value =
  | String of string
  | Integer of int64
  | Float of float
  | Boolean of bool
  | Offset_date_time of date * time * offset
  | Local_date_time of date * time
  | Local_date of date
  | Local_time of time
  | Array of item list
  | Table of table

and item = { value : value; span : span option; key : key option }
and table = (string * item) list

type error =
  | Not_utf_8
  | Syntax
  | Integer_out_of_range
  | Float_out_of_range
  | Date_time_out_of_range
  | Escape_not_a_character
  | Duplicate_key
  | Table_defined_twice
  | Not_a_table
  | Not_an_array_of_tables
  | Inline_table_closed
  | Dotted_key_into_named_table

type limit = Depth | Key_parts

type failure =
  | Invalid of { error : error; offset : int }
  | Limit_reached of { limit : limit; offset : int }
