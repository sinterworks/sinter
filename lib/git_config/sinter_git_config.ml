(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let ( let* ) = Result.bind

type key = string

let lower = String.lowercase_ascii

let key ~section ?subsection name =
  match subsection with
  | None -> lower section ^ "." ^ lower name
  | Some subsection -> lower section ^ "." ^ subsection ^ "." ^ lower name

let equal_key = String.equal

type value = string option

let int_bound = 1 lsl 31

let digit_value base c =
  let value =
    match c with
    | '0' .. '9' -> Char.code c - Char.code '0'
    | 'a' .. 'f' -> Char.code c - Char.code 'a' + 10
    | 'A' .. 'F' -> Char.code c - Char.code 'A' + 10
    | _ -> base
  in
  if value < base then Some value else None

let integer_of_text text =
  let length = String.length text in
  let rec skip k =
    if k < length && (text.[k] = ' ' || (text.[k] >= '\t' && text.[k] <= '\r'))
    then skip (k + 1)
    else k
  in
  let k = skip 0 in
  let negative, k =
    if k < length && (text.[k] = '+' || text.[k] = '-') then
      (text.[k] = '-', k + 1)
    else (false, k)
  in
  let base, k =
    if
      k + 1 < length
      && text.[k] = '0'
      && (text.[k + 1] = 'x' || text.[k + 1] = 'X')
    then (16, k + 2)
    else if k < length && text.[k] = '0' then (8, k)
    else (10, k)
  in
  let rec digits k value =
    match if k < length then digit_value base text.[k] else None with
    | Some d -> digits (k + 1) (min (int_bound + 1) ((value * base) + d))
    | None -> (k, value)
  in
  let after, magnitude = digits k 0 in
  let factor =
    if after = length then Some 1
    else if after + 1 = length then
      match text.[after] with
      | 'k' | 'K' -> Some (1 lsl 10)
      | 'm' | 'M' -> Some (1 lsl 20)
      | 'g' | 'G' -> Some (1 lsl 30)
      | _ -> None
    else None
  in
  match factor with
  | Some factor when after > k ->
      let value = magnitude * factor in
      if negative && value <= int_bound then Some (-value)
      else if (not negative) && value < int_bound then Some value
      else None
  | _ -> None

let integer value = Option.bind value integer_of_text

let boolean = function
  | None -> Some true
  | Some text -> (
      match lower text with
      | "yes" | "on" | "true" | "1" -> Some true
      | "no" | "off" | "false" | "0" | "" -> Some false
      | _ -> Option.map (fun number -> number <> 0) (integer_of_text text))

let format_version settings =
  let wanted = key ~section:"core" "repositoryformatversion" in
  List.fold_left
    (fun found (key, value) ->
      let* _ = found in
      if not (equal_key key wanted) then found
      else
        match integer value with
        | Some -1 -> Ok None
        | Some version -> Ok (Some version)
        | None -> Error value)
    (Ok None) settings

type pathname = Pathname of string | Names_no_file
type pathname_error = No_home | Unread_form | No_value

let pathname ~home = function
  | None -> Error No_value
  | Some text ->
      if String.starts_with ~prefix:"~/" text then
        match home with
        | None -> Error No_home
        | Some home ->
            Ok (Pathname (home ^ String.sub text 1 (String.length text - 1)))
      else if
        String.starts_with ~prefix:"%(prefix)/" text
        || String.starts_with ~prefix:":(optional)" text
      then Ok Names_no_file
      else if String.starts_with ~prefix:"~" text then Error Unread_form
      else Ok (Pathname text)

type syntax_error = { line : int }

exception Malformed

let is_letter c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
let is_digit c = c >= '0' && c <= '9'
let is_name_byte c = is_letter c || is_digit c || c = '-'
let is_section_byte c = is_name_byte c || c = '.'
let is_space c = c = ' ' || c = '\t'

let parse content =
  let length = String.length content in
  let body_start = 0 in
  let ending k =
    if content.[k] = '\n' then (1
      [@mutaml.skip
        "ending gives 1 only at a byte 0x0A; there peek gives the byte 0x0A in \
         both of its branches, and advance moves by max 1 of it, 1 in both \
         cases"])
    else 0
  in
  let at = ref body_start in
  let line = ref 1 in
  let name = Buffer.create length in
  let subsection = Buffer.create length in
  let bytes = Buffer.create length in
  let pending = Buffer.create length in
  let peek () =
    if !at >= length then None
    else
      match (ending !at, content.[!at]) with
      | 0, '\000' -> raise Malformed
      | 0, c -> Some c
      | _ -> Some '\n'
  in
  let advance () = at := !at + max 1 (ending !at) in
  let rec skip_comment () =
    match peek () with
    | None | Some '\n' -> ()
    | Some _ ->
        advance ();
        skip_comment ()
  in
  let rec skip_spaces () =
    match peek () with
    | Some c when is_space c ->
        advance ();
        skip_spaces ()
    | _ -> ()
  in
  let header () =
    Buffer.clear name;
    let rec read_name () =
      match peek () with
      | Some c when is_section_byte c ->
          Buffer.add_char name (Char.lowercase_ascii c);
          advance ();
          read_name ()
      | _ -> ()
    in
    read_name ();
    match peek () with
    | Some ']' when Buffer.length name > 0 ->
        advance ();
        Buffer.contents name
    | Some c when is_space c ->
        skip_spaces ();
        if peek () <> Some '"' then raise Malformed;
        advance ();
        Buffer.clear subsection;
        let rec read_subsection () =
          match peek () with
          | None | Some '\n' -> raise Malformed
          | Some '"' -> advance ()
          | Some '\\' -> (
              advance ();
              match peek () with
              | None | Some '\n' -> raise Malformed
              | Some c ->
                  Buffer.add_char subsection c;
                  advance ();
                  read_subsection ())
          | Some c ->
              Buffer.add_char subsection c;
              advance ();
              read_subsection ()
        in
        read_subsection ();
        if peek () <> Some ']' then raise Malformed;
        advance ();
        Buffer.contents name ^ "." ^ Buffer.contents subsection
    | _ -> raise Malformed
  in
  let value () =
    Buffer.clear bytes;
    Buffer.clear pending;
    let quoted = ref false in
    let add c =
      Buffer.add_buffer bytes pending;
      Buffer.clear pending;
      Buffer.add_char bytes c
    in
    let rec read () =
      match peek () with
      | None | Some '\n' -> if !quoted then raise Malformed
      | Some '\\' -> (
          advance ();
          match peek () with
          | None -> raise Malformed
          | Some '\n' ->
              advance ();
              incr line;
              read ()
          | Some c ->
              add
                (match c with
                | '"' -> '"'
                | '\\' -> '\\'
                | 'n' -> '\n'
                | 't' -> '\t'
                | 'b' -> '\b'
                | _ -> raise Malformed);
              advance ();
              read ())
      | Some '"' ->
          quoted := not !quoted;
          advance ();
          read ()
      | Some ('#' | ';') when not !quoted -> skip_comment ()
      | Some c when is_space c && not !quoted ->
          if Buffer.length bytes > 0 then Buffer.add_char pending c;
          advance ();
          read ()
      | Some c ->
          add c;
          advance ();
          read ()
    in
    read ();
    Buffer.contents bytes
  in
  let variable section =
    Buffer.clear name;
    let rec read_name () =
      match peek () with
      | Some c when is_name_byte c ->
          Buffer.add_char name (Char.lowercase_ascii c);
          advance ();
          read_name ()
      | _ -> ()
    in
    read_name ();
    skip_spaces ();
    let key = section ^ "." ^ Buffer.contents name in
    match peek () with
    | None | Some ('\n' | '#' | ';') -> (key, None)
    | Some '=' ->
        advance ();
        (key, Some (value ()))
    | Some _ -> raise Malformed
  in
  let rec lines section settings =
    match peek () with
    | None -> List.rev settings
    | Some '\n' ->
        advance ();
        incr line;
        lines section settings
    | Some c when is_space c ->
        advance ();
        lines section settings
    | Some ('#' | ';') ->
        skip_comment ();
        lines section settings
    | Some '[' ->
        advance ();
        lines (Some (header ())) settings
    | Some c when is_letter c -> (
        match section with
        | None -> raise Malformed
        | Some section -> lines (Some section) (variable section :: settings))
    | Some _ -> raise Malformed
  in
  try Ok (lines None []) with Malformed -> Error { line = !line }

module Keys = Map.Make (String)

type t = value list Keys.t

let values configuration key =
  Option.value ~default:[] (Keys.find_opt key configuration)

let last configuration key =
  match List.rev (values configuration key) with
  | [] -> None
  | value :: _ -> Some value

type file =
  | No_file
  | Folder
  | Unreadable
  | Content of { content : string; identity : (int * int) option }

type error =
  | Syntax of { pathname : string; line : int }
  | Unreadable_file of string
  | Environment of string
  | Unread_pathname of { pathname : string option; value : value }
  | Relative_without_file of value
  | No_real_path of { pathname : string option; path : string }
  | Not_an_integer of key
  | Not_a_boolean of key
  | Include_cycle of string
  | Remote_url_in_conditional_include of string
  | Remote_url_without_value
  | Limit_exceeded

type limits = { max_files : int; max_values : int }
type inclusion = Plain | Met | Unmet_hasconfig
type place = Before_hasconfig of string option | After_hasconfig

type context = {
  environment : string -> string option;
  read : string -> file;
  real_path : string -> string option;
  branch : string option;
  git_directories : string list;
  urls : string list option;
  mutable place : place;
  mutable settings : (key * value) list;
  limits : limits;
  mutable files : int;
  mutable count : int;
}

let read_file context pathname =
  context.files <- context.files + 1;
  if context.files > context.limits.max_files then Error Limit_exceeded
  else Ok (context.read pathname)

let is_remote_url key =
  String.length key >= String.length "remote..url"
  && String.starts_with ~prefix:"remote." key
  && String.ends_with ~suffix:".url" key

let hasconfig = "hasconfig:remote.*.url:"
let hasconfig_setting = "includeif." ^ hasconfig
let is_hasconfig key = String.starts_with ~prefix:hasconfig_setting key

let meet context ~pathname ~inclusion key =
  match (pathname, inclusion) with
  | Some pathname, (Met | Unmet_hasconfig) when is_remote_url key -> (
      match context.place with
      | After_hasconfig -> Error (Remote_url_in_conditional_include pathname)
      | Before_hasconfig None ->
          context.place <- Before_hasconfig (Some pathname);
          Ok ()
      | Before_hasconfig (Some _) -> Ok ())
  | _ -> (
      match context.place with
      | Before_hasconfig first when is_hasconfig key -> (
          context.place <- After_hasconfig;
          match first with
          | None -> Ok ()
          | Some pathname -> Error (Remote_url_in_conditional_include pathname))
      | _ -> Ok ())

let after ~prefix text =
  if String.starts_with ~prefix text then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix))
  else None

let condition_of key =
  match after ~prefix:"includeif." key with
  | Some rest -> (
      match String.rindex_opt rest '.' with
      | Some dot ->
          Some
            ( String.sub rest 0 dot,
              String.sub rest (dot + 1) (String.length rest - dot - 1) )
      | None -> None)
  | None -> None

let with_ending pattern =
  if String.ends_with ~suffix:"/" pattern then pattern ^ "**" else pattern

let match_any ?case_fold pattern texts =
  let pattern = Sinter_wildmatch.compile ?case_fold pattern in
  List.exists (Sinter_wildmatch.matches pattern) texts

let gitdir_of condition =
  match after ~prefix:"gitdir:" condition with
  | Some text -> Some (false, text)
  | None -> (
      match after ~prefix:"gitdir/i:" condition with
      | Some text -> Some (true, text)
      | None -> None)

let home_rest text =
  match after ~prefix:"~" text with
  | Some rest when rest = "" || String.starts_with ~prefix:"/" rest -> Some rest
  | _ -> None

let home context ~source ~value =
  match context.environment "HOME" with
  | Some "" -> Error (Unread_pathname { pathname = source; value })
  | home -> Ok home

type gitdir_pattern = Never | Always | Pattern of string

let real_path context ~source path =
  match context.real_path path with
  | Some real -> Ok real
  | None -> Error (No_real_path { pathname = source; path })

let gitdir_pattern context ~source ~value text =
  match home_rest text with
  | Some rest -> (
      let* home = home context ~source ~value in
      match home with
      | None -> Ok Never
      | Some home ->
          let* home = real_path context ~source home in
          Ok (Pattern (home ^ rest)))
  | None -> (
      match after ~prefix:"./" text with
      | Some rest -> (
          match source with
          | None -> Ok Always
          | Some file ->
              let* file = real_path context ~source file in
              Ok (Pattern (Filename.dirname file ^ "/" ^ rest)))
      | None -> Ok (Pattern text))

let gitdir context ~source ~value ~case_fold text =
  let* pattern = gitdir_pattern context ~source ~value text in
  match pattern with
  | Never -> Ok false
  | Always -> Ok true
  | Pattern pattern ->
      let pattern =
        if String.starts_with ~prefix:"/" pattern then pattern
        else "**/" ^ pattern
      in
      Ok (match_any ~case_fold (with_ending pattern) context.git_directories)

let met context ~source ~value condition =
  match gitdir_of condition with
  | Some (case_fold, text) -> gitdir context ~source ~value ~case_fold text
  | None -> (
      match after ~prefix:"onbranch:" condition with
      | Some text -> (
          match context.branch with
          | None -> Ok false
          | Some branch ->
              let pattern = Sinter_wildmatch.compile (with_ending text) in
              Ok (Sinter_wildmatch.matches pattern branch))
      | None -> (
          match after ~prefix:hasconfig condition with
          | Some text ->
              Ok (match_any text (Option.value ~default:[] context.urls))
          | None -> Ok false))

let same_file (pathname, identity) (pathname', identity') =
  match (identity, identity') with
  | Some identity, Some identity' -> identity = identity'
  | _ -> String.equal pathname pathname'

let rec include_file context ~chain ~inclusion pathname =
  let* file = read_file context pathname in
  match file with
  | No_file -> Ok ()
  | Folder | Unreadable -> Error (Unreadable_file pathname)
  | Content { content; identity } ->
      if List.exists (same_file (pathname, identity)) chain then
        Error (Include_cycle pathname)
      else apply_content context ~chain ~inclusion (pathname, identity) content

and apply_content context ~chain ~inclusion ((pathname, _) as file) content =
  match parse content with
  | Error { line } -> Error (Syntax { pathname; line })
  | Ok settings ->
      apply context ~pathname:(Some pathname) ~inclusion ~chain:(file :: chain)
        settings

and apply context ~pathname ~inclusion ~chain settings =
  let rec loop = function
    | [] -> Ok ()
    | (key, value) :: rest ->
        (match inclusion with
        | Unmet_hasconfig -> ()
        | Plain | Met -> context.settings <- (key, value) :: context.settings);
        context.count <- context.count + 1;
        let* () =
          if context.count > context.limits.max_values then Error Limit_exceeded
          else Ok ()
        in
        let* () = meet context ~pathname ~inclusion key in
        let* () =
          if key = "include.path" then
            include_value context ~source:pathname ~chain ~inclusion value
          else
            match condition_of key with
            | None -> Ok ()
            | Some (condition, "path") ->
                let* met = met context ~source:pathname ~value condition in
                if met then
                  include_value context ~source:pathname ~chain
                    ~inclusion:
                      (match inclusion with
                      | Unmet_hasconfig -> Unmet_hasconfig
                      | Plain | Met -> Met)
                    value
                else if String.starts_with ~prefix:hasconfig condition then
                  include_value context ~source:pathname ~chain
                    ~inclusion:Unmet_hasconfig value
                else Ok ()
            | Some (condition, _) -> (
                match gitdir_of condition with
                | None -> Ok ()
                | Some (_, text) ->
                    Result.map ignore
                      (gitdir_pattern context ~source:pathname ~value text))
        in
        loop rest
  in
  loop settings

and include_value context ~source ~chain ~inclusion value =
  match pathname ~home:(context.environment "HOME") value with
  | Error _ -> Error (Unread_pathname { pathname = source; value })
  | Ok Names_no_file -> Ok ()
  | Ok (Pathname path) ->
      let* full =
        if String.starts_with ~prefix:"/" path then Ok path
        else
          match source with
          | None -> Error (Relative_without_file value)
          | Some source -> Ok (Filename.concat (Filename.dirname source) path)
      in
      include_file context ~chain ~inclusion full

let outer_file context pathname =
  if pathname = "" then Ok ()
  else
    let* file = read_file context pathname in
    match file with
    | No_file | Folder | Unreadable -> Ok ()
    | Content { content; identity } ->
        apply_content context ~chain:[] ~inclusion:Plain (pathname, identity)
          content

let parse_key text =
  match (String.index_opt text '.', String.rindex_opt text '.') with
  | Some first, Some last ->
      let section = String.sub text 0 first in
      let name = String.sub text (last + 1) (String.length text - last - 1) in
      let subsection =
        if first = last then None
        else Some (String.sub text (first + 1) (last - first - 1))
      in
      if
        (section <> "" || first <> last)
        && String.for_all is_name_byte section
        && name <> ""
        && is_letter name.[0]
        && String.for_all is_name_byte name
        && not
             (Option.fold ~none:false
                ~some:(fun s ->
                  String.contains s '\n' || String.contains s '\000')
                subsection)
      then Some (key ~section ?subsection name)
      else None
  | _ -> None

let count_of context =
  match context.environment "GIT_CONFIG_COUNT" with
  | None | Some "" -> Ok 0
  | Some text -> (
      match
        if String.for_all is_digit text then int_of_string_opt text else None
      with
      | Some count -> Ok count
      | None -> Error (Environment "GIT_CONFIG_COUNT"))

let environment_settings context =
  let* count = count_of context in
  let rec pairs n =
    if n >= count then Ok ()
    else
      let key_name = "GIT_CONFIG_KEY_" ^ string_of_int n in
      let value_name = "GIT_CONFIG_VALUE_" ^ string_of_int n in
      match Option.bind (context.environment key_name) parse_key with
      | None -> Error (Environment key_name)
      | Some key -> (
          match context.environment value_name with
          | None -> Error (Environment value_name)
          | Some value ->
              let* () =
                apply context ~pathname:None ~inclusion:Plain ~chain:[]
                  [ (key, Some value) ]
              in
              pairs (n + 1))
  in
  pairs 0

let system_files context =
  let* skip =
    match context.environment "GIT_CONFIG_NOSYSTEM" with
    | None -> Ok false
    | Some text -> (
        match boolean (Some text) with
        | Some skip -> Ok skip
        | None -> Error (Environment "GIT_CONFIG_NOSYSTEM"))
  in
  if skip then Ok []
  else
    Ok
      [
        Option.value ~default:"/etc/gitconfig"
          (context.environment "GIT_CONFIG_SYSTEM");
      ]

let global_files context =
  match context.environment "GIT_CONFIG_GLOBAL" with
  | Some pathname -> [ pathname ]
  | None ->
      let home = context.environment "HOME" in
      let xdg =
        match context.environment "XDG_CONFIG_HOME" with
        | Some folder when folder <> "" -> Some (folder ^ "/git/config")
        | _ -> Option.map (fun home -> home ^ "/.config/git/config") home
      in
      List.filter_map Fun.id
        [ xdg; Option.map (fun home -> home ^ "/.gitconfig") home ]

let worktree_config ~working_tree_folder settings =
  let wanted = key ~section:"extensions" "worktreeConfig" in
  match
    List.rev
      (List.filter_map
         (fun (key, value) -> if key = wanted then Some value else None)
         settings)
  with
  | [] -> Ok []
  | value :: _ -> (
      match boolean value with
      | Some true ->
          Ok [ Filename.concat working_tree_folder "config.worktree" ]
      | Some false -> Ok []
      | None -> Error (Not_a_boolean wanted))

let rec each f = function
  | [] -> Ok ()
  | x :: rest ->
      let* () = f x in
      each f rest

let collect ~limits ~environment ~read ~real_path ~branch ~git_folder ~extra
    ~git_directories ~urls =
  if limits.max_files < 0 || limits.max_values < 0 then
    invalid_arg "Sinter_git_config: a negative limit";
  let context =
    {
      environment;
      read;
      real_path;
      branch;
      git_directories;
      urls;
      place = Before_hasconfig None;
      settings = [];
      limits;
      files = 0;
      count = 0;
    }
  in
  let local = Filename.concat git_folder "config" in
  let* system = system_files context in
  let* () = each (outer_file context) system in
  let* () = each (outer_file context) (global_files context) in
  let* local_file = read_file context local in
  let* local_settings =
    match local_file with
    | No_file -> Ok []
    | Folder | Unreadable -> Error (Unreadable_file local)
    | Content { content; identity } -> (
        match parse content with
        | Error { line } -> Error (Syntax { pathname = local; line })
        | Ok settings ->
            let* () =
              apply context ~pathname:(Some local) ~inclusion:Plain
                ~chain:[ (local, identity) ]
                settings
            in
            Ok settings)
  in
  let* extra = extra local_settings in
  let* () =
    each
      (fun pathname -> include_file context ~chain:[] ~inclusion:Plain pathname)
      extra
  in
  let* () = environment_settings context in
  Ok
    ( List.rev context.settings,
      match context.place with
      | After_hasconfig -> true
      | Before_hasconfig _ -> false )

let build ~limits ~environment ~read ~real_path ~branch ~git_folder ~extra
    ~git_directories =
  let* settings, conditional =
    collect ~limits ~environment ~read ~real_path ~branch ~git_folder ~extra
      ~git_directories ~urls:None
  in
  let* settings =
    if not conditional then Ok settings
    else
      let* urls =
        List.fold_left
          (fun found (key, value) ->
            let* found = found in
            if is_remote_url key then
              match value with
              | Some url -> Ok (url :: found)
              | None -> Error Remote_url_without_value
            else Ok found)
          (Ok []) settings
      in
      let* settings, _ =
        collect ~limits ~environment ~read ~real_path ~branch ~git_folder ~extra
          ~git_directories ~urls:(Some urls)
      in
      Ok settings
  in
  Ok
    (List.fold_left
       (fun table (key, value) ->
         Keys.add key (value :: values table key) table)
       Keys.empty (List.rev settings))

let of_repository ~limits ~environment ~read ~real_path ~git_directories ~branch
    git_folder =
  build ~limits ~environment ~read ~real_path ~branch ~git_folder
    ~extra:(fun _ -> Ok [])
    ~git_directories

let of_working_tree ~limits ~environment ~read ~real_path ~git_folder
    ~git_directories ~branch working_tree_folder =
  build ~limits ~environment ~read ~real_path ~branch ~git_folder
    ~extra:(worktree_config ~working_tree_folder)
    ~git_directories

type upstream_error = No_value_of of key | Invalid_refspec of string

let count_stars text =
  String.fold_left (fun count c -> if c = '*' then count + 1 else count) 0 text

let contains text part =
  let n = String.length text and m = String.length part in
  let rec from k = k + m <= n && (String.sub text k m = part || from (k + 1)) in
  from 0

let is_refspec_name name =
  name <> "@"
  && (not (String.starts_with ~prefix:"/" name))
  && (not (String.ends_with ~suffix:"/" name))
  && (not (String.starts_with ~prefix:"." name))
  && (not (String.ends_with ~suffix:"." name))
  && (not (String.ends_with ~suffix:".lock" name))
  && (not (List.exists (contains name) [ "//"; "/."; ".lock/"; ".."; "@{" ]))
  && String.for_all
       (fun c -> c > ' ' && c <> '\127' && not (String.contains "~^:?[\\" c))
       name
  && count_stars name <= 1

let is_source source = source = "" || source = "@" || is_refspec_name source

type refspec = Negative | Positive of { source : string; map : string option }

let refspec value =
  match String.split_on_char ':' value with
  | [ negative ] when String.starts_with ~prefix:"^" negative ->
      let source = String.sub negative 1 (String.length negative - 1) in
      if source <> "" && is_source source then Some Negative else None
  | parts -> (
      let positive part =
        if String.starts_with ~prefix:"+" part then
          String.sub part 1 (String.length part - 1)
        else part
      in
      match parts with
      | [ source ] ->
          let source = positive source in
          if is_source source && count_stars source = 0 then
            Some (Positive { source; map = None })
          else None
      | [ source; destination ] ->
          let source = positive source in
          if
            is_source source
            && (destination = "" || is_refspec_name destination)
            && count_stars source = count_stars destination
          then Some (Positive { source; map = Some destination })
          else None
      | _ -> None)

let fill text bytes =
  match String.index_opt text '*' with
  | None -> text
  | Some star ->
      String.sub text 0 star ^ bytes
      ^ String.sub text (star + 1) (String.length text - star - 1)

let fit source merge =
  match String.index_opt source '*' with
  | None -> if String.equal source merge then Some "" else None
  | Some star ->
      let prefix = String.sub source 0 star in
      let suffix =
        String.sub source (star + 1) (String.length source - star - 1)
      in
      if
        String.length merge >= String.length prefix + String.length suffix
        && String.starts_with ~prefix merge
        && String.ends_with ~suffix merge
      then
        Some
          (String.sub merge (String.length prefix)
             (String.length merge - String.length prefix - String.length suffix))
      else None

(* @satisfies changes#give-default-branch-commits=v1
   A fetch refspec maps the merge ref M when it is positive, has a
   destination, and its source, with `@` as `HEAD`, is M or, with the bytes
   s in place of its one asterisk, is M; it maps M to the destination with s
   in place of its asterisk. *)
let mapping merge = function
  | Negative | Positive { map = None; _ } -> None
  | Positive { source; map = Some destination } ->
      let source = if source = "@" then "HEAD" else source in
      Option.map (fill destination) (fit source merge)

let is_remote_fetch key =
  String.length key >= String.length "remote..fetch"
  && String.starts_with ~prefix:"remote." key
  && String.ends_with ~suffix:".fetch" key

(* @satisfies changes#give-default-branch-commits=v1
   Each value of a setting `remote.<name>.fetch` is a fetch refspec, or the
   upstream is an error and gives no commit of the default branch. *)
let refspecs configuration =
  Keys.fold
    (fun key values found ->
      let* found = found in
      if not (is_remote_fetch key) then Ok found
      else
        let* parsed =
          List.fold_left
            (fun parsed value ->
              let* parsed = parsed in
              match value with
              | None -> Error (No_value_of key)
              | Some text -> (
                  match refspec text with
                  | Some spec -> Ok (spec :: parsed)
                  | None -> Error (Invalid_refspec text)))
            (Ok []) values
        in
        Ok (Keys.add key (List.rev parsed) found))
    configuration (Ok Keys.empty)

(* @satisfies changes#give-default-branch-commits=v1
   The upstream of b is M when r is ".", and otherwise the destination to
   which the first fetch refspec of r, in the order of its values, that maps
   M maps it, with no upstream for an empty destination; with no value of
   either setting, b has no upstream. *)
let upstream configuration branch =
  let* specs = refspecs configuration in
  let name =
    Sinter_text.Text.encode (Sinter_branch_names.Branch_name.to_text branch)
  in
  let merge_key = key ~section:"branch" ~subsection:name "merge" in
  let remote_key = key ~section:"branch" ~subsection:name "remote" in
  match (values configuration merge_key, last configuration remote_key) with
  | [], _ | _, None -> Ok None
  | None :: _, _ -> Error (No_value_of merge_key)
  | _, Some None -> Error (No_value_of remote_key)
  | Some merge :: _, Some (Some ".") -> Ok (Some merge)
  | Some merge :: _, Some (Some remote) -> (
      let fetch_key = key ~section:"remote" ~subsection:remote "fetch" in
      match
        List.find_map (mapping merge)
          (Option.value ~default:[] (Keys.find_opt fetch_key specs))
      with
      | Some "" | None -> Ok None
      | Some destination -> Ok (Some destination))
