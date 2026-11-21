(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let parse text =
  match Wasm.Parse.Module.parse_string text with
  | _, { Wasm.Source.it = Wasm.Script.Textual m; _ } -> m
  | _ -> failwith "the text is not a module in the text format"
  | exception Wasm.Parse.Syntax (_, message) -> failwith ("syntax: " ^ message)

let of_text_unchecked text = Wasm.Encode.encode (parse text)

let of_text text =
  let m = parse text in
  (try Wasm.Valid.check_module m
   with Wasm.Valid.Invalid (_, message) -> failwith ("invalid: " ^ message));
  Wasm.Encode.encode m

let hex bytes =
  String.concat ""
    (List.init (String.length bytes) (fun i ->
         Printf.sprintf "%02x" (Char.code bytes.[i])))

let of_hex text =
  if String.length text mod 2 <> 0 then failwith "odd hex text";
  String.init
    (String.length text / 2)
    (fun i ->
      match int_of_string_opt ("0x" ^ String.sub text (2 * i) 2) with
      | Some byte -> Char.chr byte
      | None -> failwith "not a hex text")

let u32 n =
  if n < 0 || n > 0xFFFF_FFFF then invalid_arg "u32";
  let buffer = Buffer.create 5 in
  let rec go n =
    let low = n land 0x7f and rest = n lsr 7 in
    if rest = 0 then Buffer.add_char buffer (Char.chr low)
    else (
      Buffer.add_char buffer (Char.chr (low lor 0x80));
      go rest)
  in
  go n;
  Buffer.contents buffer

let s64 n =
  let buffer = Buffer.create 10 in
  let rec go n =
    let low = Int64.to_int (Int64.logand n 0x7fL) in
    let rest = Int64.shift_right n 7 in
    let finished =
      (rest = 0L && low land 0x40 = 0) || (rest = -1L && low land 0x40 <> 0)
    in
    if finished then Buffer.add_char buffer (Char.chr low)
    else (
      Buffer.add_char buffer (Char.chr (low lor 0x80));
      go rest)
  in
  go n;
  Buffer.contents buffer

let s32 n = s64 (Int64.of_int32 n)
let vec items = u32 (List.length items) ^ String.concat "" items
let name text = u32 (String.length text) ^ text

let section id payload =
  String.make 1 (Char.chr id) ^ u32 (String.length payload) ^ payload

let module_ sections = "\x00asm\x01\x00\x00\x00" ^ String.concat "" sections

type part = {
  types : string list;
  memory : string;
  extra_sections : (int * string) list;
  feature : string;
  extra_funcs : (int * string) list;
  globals : string list;
}

let base =
  {
    types = [];
    memory = vec [ "\x00\x01" ];
    extra_sections = [];
    feature = "";
    extra_funcs = [];
    globals = [];
  }

let section_order = [ 1; 2; 3; 4; 5; 13; 6; 7; 8; 9; 12; 10; 11; 0 ]

let adapter part =
  let adapter_types =
    [
      "\x60\x00\x01\x7f";
      "\x60\x01\x7f\x01\x7f";
      "\x60\x04\x7f\x7f\x7f\x7f\x01\x7e";
      "\x60\x00\x00";
    ]
  in
  let body code = name ("\x00" ^ code ^ "\x0b") in
  let bodies =
    [
      body "\x10\x04\x41\x01";
      body "\x41\x10";
      body "\x42\x00";
      body "\x42\x00";
      body part.feature;
    ]
    @ List.map (fun (_, code) -> body code) part.extra_funcs
  in
  let export text kind index =
    name text ^ String.make 1 (Char.chr kind) ^ u32 index
  in
  let own =
    [
      (1, vec (adapter_types @ part.types));
      (3, vec (List.map u32 ([ 0; 1; 2; 2; 3 ] @ List.map fst part.extra_funcs)));
      ( 7,
        vec
          [
            export "memory" 2 0;
            export "sinter_interface" 0 0;
            export "sinter_alloc" 0 1;
            export "sinter_recognise" 0 2;
            export "sinter_bind" 0 3;
          ] );
      (10, vec bodies);
    ]
    @ (if part.memory = "" then [] else [ (5, part.memory) ])
    @ if part.globals = [] then [] else [ (6, vec part.globals) ]
  in
  let all = own @ part.extra_sections in
  let rank id =
    let rec find i = function
      | [] -> List.length section_order
      | x :: rest -> if x = id then i else find (i + 1) rest
    in
    find 0 section_order
  in
  let sorted =
    List.stable_sort (fun (a, _) (b, _) -> compare (rank a) (rank b)) all
  in
  module_ (List.map (fun (id, payload) -> section id payload) sorted)

type verdict = Refused of string | Accepted

let decoded bytes =
  match Wasm.Decode.decode "module" bytes with
  | m -> (
      match Wasm.Valid.check_module m with
      | () -> Ok m
      | exception Wasm.Valid.Invalid (_, message) ->
          Error ("invalid: " ^ message))
  | exception Wasm.Decode.Code (_, message) -> Error ("malformed: " ^ message)
  | exception exn -> Error ("malformed: " ^ Printexc.to_string exn)

let reference bytes =
  match decoded bytes with Ok _ -> Accepted | Error message -> Refused message

type decision = Valid | Invalid | Unknown

let i32 = Wasm.Types.NumType Wasm.Types.I32Type
let i64 = Wasm.Types.NumType Wasm.Types.I64Type

let wanted =
  let open Wasm.Types in
  [
    ("sinter_interface", fun t -> t = ExternFuncType (FuncType ([], [ i32 ])));
    ("sinter_alloc", fun t -> t = ExternFuncType (FuncType ([ i32 ], [ i32 ])));
    ( "sinter_recognise",
      fun t -> t = ExternFuncType (FuncType ([ i32; i32; i32; i32 ], [ i64 ]))
    );
    ( "sinter_bind",
      fun t -> t = ExternFuncType (FuncType ([ i32; i32; i32; i32 ], [ i64 ]))
    );
    ("memory", function ExternMemoryType _ -> true | _ -> false);
  ]

let reference_decision bytes =
  match decoded bytes with
  | Error _ -> Invalid
  | Ok m -> (
      let exports =
        List.map
          (fun (e : Wasm.Ast.export) ->
            (Wasm.Utf8.encode e.it.name, Wasm.Ast.export_type m e))
          m.it.exports
      in
      let has (export, fits) =
        match List.assoc_opt export exports with
        | Some t -> fits t
        | None -> false
      in
      if m.it.imports <> [] || not (List.for_all has wanted) then Invalid
      else
        match
          let instance = Wasm.Eval.init m [] in
          match
            Wasm.Instance.export instance (Wasm.Utf8.decode "sinter_interface")
          with
          | Some (Wasm.Instance.ExternFunc f) -> Wasm.Eval.invoke f []
          | _ -> []
        with
        | [ Wasm.Values.Num (Wasm.Values.I32 1l) ] -> Valid
        | _ -> Invalid
        | exception (Wasm.Eval.Trap _ | Wasm.Eval.Link _) -> Invalid
        | exception
            ( Wasm.Eval.Exhaustion _ | Wasm.Eval.Crash _ | Stack_overflow
            | Out_of_memory ) ->
            Unknown)
