(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

type token =
  | Byte of char
  | Any_byte
  | Star
  | Names
  | Anything
  | Bracket of { members : (char -> bool) list; negated : bool }

type compiled = { tokens : token array; case_fold : bool }
type t = compiled option

let lower c = Char.lowercase_ascii c

let class_member name c =
  let code = Char.code c in
  let is_upper = c >= 'A' && c <= 'Z' in
  let is_lower = c >= 'a' && c <= 'z' in
  let is_digit = c >= '0' && c <= '9' in
  let is_alpha = is_upper || is_lower in
  let is_graph = code > 0x20 && code < 0x7F in
  match name with
  | "alnum" -> Some (is_alpha || is_digit)
  | "alpha" -> Some is_alpha
  | "blank" -> Some (c = ' ' || c = '\t')
  | "cntrl" -> Some (code < 0x20 || code = 0x7F)
  | "digit" -> Some is_digit
  | "graph" -> Some is_graph
  | "lower" -> Some is_lower
  | "print" -> Some (is_graph || c = ' ')
  | "punct" -> Some (is_graph && not (is_alpha || is_digit))
  | "space" -> Some (c = ' ' || (code >= 0x09 && code <= 0x0D))
  | "upper" -> Some is_upper
  | "xdigit" -> Some (is_digit || (lower c >= 'a' && lower c <= 'f'))
  | _ -> None

let bracket pattern start =
  let length = String.length pattern in
  let negated =
    start < length && (pattern.[start] = '!' || pattern.[start] = '^')
  in
  let first = if negated then start + 1 else start in
  let member_at k =
    if pattern.[k] = '\\' then
      if k + 1 < length then Some (pattern.[k + 1], k + 2) else None
    else Some (pattern.[k], k + 1)
  in
  let rec class_end k =
    if k + 1 >= length then None
    else if pattern.[k] = ':' && pattern.[k + 1] = ']' then Some k
    else class_end (k + 1)
  in
  let rec members_from k members =
    if k >= length then None
    else if pattern.[k] = ']' && k > first then
      Some (Bracket { members; negated }, k + 1)
    else if pattern.[k] = '[' && k + 1 < length && pattern.[k + 1] = ':' then
      match
        class_end
          (k
         + (2
           [@mutaml.skip
             "a search from k + 3 differs only when the next :] starts at k + \
              2, an empty class name; then the name that it gives holds :] or \
              is empty, and no class has such a name, so both give no match"]))
      with
      | Some close -> (
          let name = String.sub pattern (k + 2) (close - k - 2) in
          match class_member name 'a' with
          | None -> None
          | Some _ ->
              members_from (close + 2)
                ((fun c -> class_member name c = Some true) :: members))
      | None -> None
    else
      match member_at k with
      | None -> None
      | Some (low, next) ->
          if
            next + 1 < length
            && pattern.[next] = '-'
            && pattern.[next + 1] <> ']'
          then
            match member_at (next + 1) with
            | None -> None
            | Some (high, after) ->
                let high = max low high in
                members_from after ((fun c -> low <= c && c <= high) :: members)
          else members_from next (Char.equal low :: members)
  in
  members_from first []

let compile ?(case_fold = false) pattern =
  let length = String.length pattern in
  let rec tokens k found =
    if k >= length then Some (List.rev found)
    else
      match pattern.[k] with
      | '\\' ->
          if k + 1 < length then tokens (k + 2) (Byte pattern.[k + 1] :: found)
          else None
      | '?' -> tokens (k + 1) (Any_byte :: found)
      | '*' ->
          let rec run_end j =
            if j < length && pattern.[j] = '*' then run_end (j + 1) else j
          in
          let stop = run_end k in
          let bounded_before = k = 0 || pattern.[k - 1] = '/' in
          if stop - k >= 2 && bounded_before && stop = length then
            tokens stop (Anything :: found)
          else if stop - k >= 2 && bounded_before && pattern.[stop] = '/' then
            tokens (stop + 1) (Names :: found)
          else if
            stop - k >= 2
            && bounded_before
            && pattern.[stop] = '\\'
            && stop + 1 < length
            && pattern.[stop + 1] = '/'
          then tokens stop (Anything :: found)
          else tokens stop (Star :: found)
      | '[' -> (
          match bracket pattern (k + 1) with
          | None -> None
          | Some (token, next) -> tokens next (token :: found))
      | c -> tokens (k + 1) (Byte c :: found)
  in
  match tokens 0 [] with
  | Some found -> Some { tokens = Array.of_list found; case_fold }
  | None -> None

let matches pattern pathname =
  match pattern with
  | None -> false
  | Some { tokens; case_fold } ->
      let size = String.length pathname in
      let next = Array.make (size + 1) false in
      next.(size) <- true;
      let row = Array.copy next in
      let same a b = if case_fold then lower a = lower b else a = b in
      for index = Array.length tokens - 1 downto 0 do
        let later = ref false in
        for at = size downto 0 do
          let byte_fits fits =
            at < size
            && pathname.[at] <> '/'
            && fits pathname.[at]
            && next.(at + 1)
          in
          row.(at) <-
            (match tokens.(index) with
            | Byte c -> at < size && same pathname.[at] c && next.(at + 1)
            | Any_byte -> byte_fits (fun _ -> true)
            | Bracket { members; negated } ->
                let fits c = List.exists (fun member -> member c) members in
                byte_fits (fun c ->
                    (fits c
                    || case_fold
                       && (fits (lower c) || fits (Char.uppercase_ascii c)))
                    <> negated)
            | Star ->
                next.(at) || (at < size && pathname.[at] <> '/' && row.(at + 1))
            | Anything -> next.(at) || (at < size && row.(at + 1))
            | Names ->
                later :=
                  !later || (at < size && pathname.[at] = '/' && next.(at + 1));
                next.(at) || !later)
        done;
        Array.blit row 0 next 0 (size + 1)
      done;
      next.(0)
