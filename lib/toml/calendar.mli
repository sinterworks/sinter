(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

(** The ranges of the parts of dates, times, and offsets. *)

val date_is_valid : Types.date -> bool
(** [date_is_valid date] is [true] when, and only when, [date.month] is from 1
    to 12 and [date.day] is from 1 to the number of days of that month in the
    year [date.year] of the proleptic Gregorian calendar. *)

val time_is_valid : Types.time -> bool
(** [time_is_valid time] is [true] when, and only when, [time.hour] is at most
    23, [time.minute] at most 59, and [time.second] at most 60. *)

val offset_is_valid : hours:int -> minutes:int -> bool
(** [offset_is_valid ~hours ~minutes] is [true] when, and only when, [hours] is
    at most 23 and [minutes] at most 59. *)
