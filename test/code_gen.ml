(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_text
module Gen = QCheck2.Gen
module R = Code_reference

type case = { sigils : R.sigils; source : string; nodes : R.node list }

type item =
  | Line_comment of {
      sigil : string;
      content : string;
      tagged : bool;
      eol : bool;
    }
  | Block_comment of {
      pair : string * string;
      lines : (string * string option * string) list;
      tagged : bool;
    }
  | Code of string
  | Decoration of string
  | Definition of {
      header : string;
      items : item list;
      definition : bool;
      test : R.piece list list option;
    }

let sigils_gen =
  Gen.oneof_list
    [
      { R.line = [ "//" ]; block = []; inner = [] };
      {
        R.line = [ "//"; "///" ];
        block = [ ("/*", "*/"); ("/**", "*/") ];
        inner = [ "*" ];
      };
      { R.line = []; block = [ ("(*", "*)") ]; inner = [] };
      { R.line = [ "#" ]; block = []; inner = [] };
      { R.line = [ "--" ]; block = [ ("{-", "-}") ]; inner = [ "|"; "||" ] };
    ]

let contents =
  [
    "";
    " @req a=v1";
    "@req b=v1";
    " @cites c=v1";
    " @spec d#s=v1";
    " @verifies x#y=v2";
    " text";
    " More text.";
    " \xc3\xa9t\xc3\xa9";
    "  @param x";
    "\t@ack";
    " a */ b";
    " *";
    "- a";
    "  - a1";
    "   ";
  ]

let indents = [ ""; " "; "  "; "   "; "\t"; "\t\t"; " \t"; "     " ]
let codes = [ "x();"; "let y = 1"; "}"; "a"; "\xc3\xa9;" ]
let decorations = [ "#[test]"; "@Test"; "#[cfg(x)]" ]
let headers = [ "fn f() "; "module M "; "it(\"adds\", () => "; "def g"; "" ]

let names =
  [
    [ [ R.Text_piece "t" ] ];
    [ [ R.Text_piece "math" ]; [ R.Text_piece "adds "; R.Placeholder "${n}" ] ];
    [ [] ];
  ]

let line_separators = [ "\n"; "\r\n"; "\n\n"; "\n  "; "\n\t\n"; "\r\n\r\n" ]
let separators = line_separators @ [ " "; "\t"; ""; "\r"; " \r" ]

let leaf_gen sigils =
  let line_gen =
    match sigils.R.line with
    | [] -> []
    | line ->
        [
          Gen.map
            (fun (sigil, content, tagged, eol) ->
              Line_comment { sigil; content; tagged; eol })
            (Gen.quad (Gen.oneof_list line) (Gen.oneof_list contents) Gen.bool
               Gen.bool);
        ]
  in
  let block_gen =
    match sigils.R.block with
    | [] -> []
    | block ->
        [
          Gen.map
            (fun (pair, lines, tagged) -> Block_comment { pair; lines; tagged })
            (Gen.triple (Gen.oneof_list block)
               (Gen.list_size (Gen.int_range 1 5)
                  (Gen.triple (Gen.oneof_list indents)
                     (Gen.option (Gen.oneof_list (sigils.R.inner @ [ " " ])))
                     (Gen.oneof_list contents)))
               Gen.bool);
        ]
  in
  Gen.oneof
    (line_gen @ block_gen
    @ [
        Gen.map (fun c -> Code c) (Gen.oneof_list codes);
        Gen.map (fun d -> Decoration d) (Gen.oneof_list decorations);
      ])

let rec items_gen sigils depth =
  Gen.list_size (Gen.int_range 0 5)
    (if depth = 0 then leaf_gen sigils
     else
       Gen.oneof_weighted
         [
           (4, leaf_gen sigils);
           ( 1,
             Gen.map
               (fun (header, items, definition, test) ->
                 let definition = definition || test = None in
                 Definition { header; items; definition; test })
               (Gen.quad (Gen.oneof_list headers)
                  (items_gen sigils (depth - 1))
                  Gen.bool
                  (Gen.option (Gen.oneof_list names))) );
         ])

let length_of string =
  match Text.decode string with
  | Ok text -> Text.length text
  | Error _ -> invalid_arg "length_of"

let render items separators_list bom =
  let buffer = Buffer.create 64 in
  let at = ref 0 in
  let add s =
    Buffer.add_string buffer s;
    at := !at + length_of s
  in
  let nodes = ref [] in
  let emit node = nodes := node :: !nodes in
  let separators = ref separators_list in
  let next_separator after_line =
    match !separators with
    | [] -> if after_line then "\n" else " "
    | s :: rest ->
        separators := rest;
        if
          after_line
          && not
               (String.length s > 0
               && (s.[0] = '\n'
                  || (s.[0] = '\r' && String.length s > 1 && s.[1] = '\n')))
        then "\n"
        else s
  in
  if bom then add "\xef\xbb\xbf";
  let rec item = function
    | Line_comment { sigil; content; tagged; eol } ->
        let from = !at in
        add sigil;
        add content;
        let until = !at in
        let separator = next_separator true in
        let ending =
          if String.length separator > 0 && separator.[0] = '\r' then 2 else 1
        in
        add separator;
        emit
          {
            R.run =
              { Text.from; until = (if eol then until + ending else until) };
            comment = Some (if tagged then R.Tagged else R.Untagged);
            body = None;
            decoration = false;
            test = None;
          }
    | Block_comment { pair = opening, closing; lines; tagged } ->
        let from = !at in
        add opening;
        List.iteri
          (fun k (indent, inner, line) ->
            if k > 0 then (
              add "\n";
              add indent;
              match inner with Some s -> add s | None -> ());
            add line)
          lines;
        add closing;
        emit
          {
            R.run = { Text.from; until = !at };
            comment = Some (if tagged then R.Tagged else R.Untagged);
            body = None;
            decoration = false;
            test = None;
          };
        add (next_separator false)
    | Code c ->
        add c;
        add (next_separator false)
    | Decoration d ->
        let from = !at in
        add d;
        emit
          {
            R.run = { Text.from; until = !at };
            comment = None;
            body = None;
            decoration = true;
            test = None;
          };
        add (next_separator false)
    | Definition { header; items; definition; test } ->
        let from = !at in
        let saved = !nodes in
        nodes := [];
        add header;
        let body_from = !at in
        add "{";
        add (next_separator false);
        List.iter item items;
        add "}";
        let until = !at in
        let inner = !nodes in
        nodes :=
          inner
          @ {
              R.run = { Text.from; until };
              comment = None;
              body =
                (if definition then Some [ { Text.from = body_from; until } ]
                 else None);
              decoration = false;
              test;
            }
            :: saved;
        add (next_separator false)
  in
  List.iter item items;
  (Buffer.contents buffer, List.rev !nodes)

let shaped =
  Gen.(
    sigils_gen >>= fun sigils ->
    map
      (fun (items, separators, bom) ->
        let source, nodes = render items separators bom in
        { sigils; source; nodes })
      (triple (items_gen sigils 2)
         (list_size (int_range 0 20) (oneof_list separators))
         (oneof_weighted [ (4, return false); (1, return true) ])))

let role_gen =
  Gen.(
    map
      (fun ((comment, definition), (decoration, test)) ->
        let none =
          comment = None && (not definition) && (not decoration) && test = None
        in
        (comment, definition || none, decoration, test))
      (pair
         (pair (option (oneof_list [ R.Tagged; R.Untagged ])) bool)
         (pair bool (option (oneof_list names)))))

let run_gen text =
  let body = Text.body text in
  Gen.(
    map
      (fun (a, b) ->
        let a = body.Text.from + a and b = body.Text.from + b in
        { Text.from = min a b; until = max a b })
      (pair
         (int_range 0 (body.Text.until - body.Text.from))
         (int_range 0 (body.Text.until - body.Text.from))))

let with_role (comment, definition, decoration, test) node =
  {
    node with
    R.comment =
      (match comment with Some _ -> comment | None -> node.R.comment);
    body =
      (if definition && node.R.body = None then Some [ node.R.run ]
       else node.R.body);
    decoration = decoration || node.R.decoration;
    test = (match test with Some _ -> test | None -> node.R.test);
  }

let insert k x list =
  let rec go i = function
    | rest when i = k -> x :: rest
    | [] -> [ x ]
    | y :: rest -> y :: go (i + 1) rest
  in
  go 0 list

let tree_order nodes =
  let rec ok = function
    | [] -> true
    | a :: rest ->
        List.for_all
          (fun b ->
            a.R.run.Text.from <= b.R.run.Text.from
            && (b.R.run.Text.until <= a.R.run.Text.until
               || a.R.run.Text.until <= b.R.run.Text.from))
          rest
        && ok rest
  in
  ok nodes

let change text nodes =
  let n = List.length nodes in
  Gen.(
    oneof_weighted
      [
        ( 2,
          map
            (fun ((run, role), k) ->
              let added =
                insert k
                  (with_role role
                     {
                       R.run;
                       comment = None;
                       body = None;
                       decoration = false;
                       test = None;
                     })
                  nodes
              in
              if tree_order added then added else nodes)
            (pair (pair (run_gen text) role_gen) (int_range 0 n)) );
        ( (if n = 0 then 0 else 2),
          map
            (fun (role, k) ->
              List.mapi
                (fun i node -> if i = k then with_role role node else node)
                nodes)
            (pair role_gen (int_range 0 (max 0 (n - 1)))) );
      ])

let mixed =
  Gen.(
    shaped >>= fun case ->
    match Text.decode case.source with
    | Error _ -> return case
    | Ok text ->
        int_range 1 6 >>= fun count ->
        let rec go k nodes =
          if k = 0 then return nodes else change text nodes >>= go (k - 1)
        in
        map (fun nodes -> { case with nodes }) (go count case.nodes))

let print_run { Text.from; until } = Printf.sprintf "%d-%d" from until

let print_piece = function
  | R.Text_piece t -> Printf.sprintf "text %S" t
  | R.Placeholder t -> Printf.sprintf "placeholder %S" t

let print { sigils; source; nodes } =
  Printf.sprintf "line [%s] block [%s] inner [%s]\ntext %S\nnodes\n%s"
    (String.concat " " sigils.R.line)
    (String.concat " " (List.map (fun (a, b) -> a ^ " " ^ b) sigils.R.block))
    (String.concat " " sigils.R.inner)
    source
    (String.concat "\n"
       (List.mapi
          (fun k node ->
            Printf.sprintf "%d: %s%s%s%s%s" k (print_run node.R.run)
              (match node.R.comment with
              | Some R.Tagged -> " tagged"
              | Some R.Untagged -> " untagged"
              | None -> "")
              (match node.R.body with
              | Some runs ->
                  " body " ^ String.concat "," (List.map print_run runs)
              | None -> "")
              (if node.R.decoration then " decoration" else "")
              (match node.R.test with
              | Some path ->
                  " test "
                  ^ String.concat " / "
                      (List.map
                         (fun own ->
                           "["
                           ^ String.concat "; " (List.map print_piece own)
                           ^ "]")
                         path)
              | None -> ""))
          nodes))
