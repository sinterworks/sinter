(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let is_leap_year year =
  (year mod 4 = 0 && year mod 100 <> 0) || year mod 400 = 0

let days_in_month ~year ~month =
  match month with
  | 2 -> if is_leap_year year then 29 else 28
  | 4 | 6 | 9 | 11 -> 30
  | _ -> 31

(* @satisfies data-forms#read-toml=v1
   A local date, a local date-time, and an offset date-time with a month
   outside 1 to 12, or a day that its month does not have in its year, is a
   value error. *)
let date_is_valid (date : Types.date) =
  date.month >= 1 && date.month <= 12 && date.day >= 1
  && date.day <= days_in_month ~year:date.year ~month:date.month

(* @satisfies data-forms#read-toml=v1
   An hour above 23 or a minute above 59 is a value error, and the second 60
   is valid at every hour and minute, by the rule toml-leap-second. *)
let time_is_valid (time : Types.time) =
  time.hour <= 23 && time.minute <= 59 && time.second <= 60

(* @satisfies data-forms#read-toml=v1
   An offset with an hour above 23 or a minute above 59 is a value error. *)
let offset_is_valid ~hours ~minutes = hours <= 23 && minutes <= 59
