(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_wasm_engine
open Sinter_adapters
open Sinter_adapter_protocol
module W = Wasm_modules
module F = Adapter_fixtures
module P = Test_adapter_protocol
module Gen = QCheck2.Gen

let engine =
  lazy
    (match Engine.create ~stack:524_288 with
    | Ok engine -> engine
    | Error (Not_made message) -> Alcotest.failf "no engine: %s" message)

let limits ~fuel ~memory ~table =
  match Instance.limits ~fuel ~memory ~table with
  | Ok limits -> limits
  | Error (Negative _) -> invalid_arg "Test_adapters.limits"

let generous = limits ~fuel:1_000_000_000 ~memory:(1 lsl 28) ~table:100_000
let small = limits ~fuel:200_000 ~memory:(1 lsl 20) ~table:1_000

let decide ?(limits = generous) bytes =
  Adapter.decide ~limits (Lazy.force engine) bytes

let case name action = Alcotest.test_case name `Quick action

let property ?(count = 100) name gen ?print check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ?print gen check)

let invalid_text = function
  | Adapter.Not_a_module message -> "not a module: " ^ message
  | Imports n -> Printf.sprintf "%d imports" n
  | Missing_export name -> "no export " ^ name
  | Wrong_export name -> "a wrong export " ^ name
  | Instantiation_failed _ -> "the instantiation failed"
  | Interface_failed _ -> "sinter_interface failed"
  | Interface_version v -> Printf.sprintf "the version %ld" v

let decision_text = function
  | Ok _ -> "valid"
  | Error invalid -> "invalid (" ^ invalid_text invalid ^ ")"

let is_valid what bytes =
  match decide bytes with
  | Ok _ -> ()
  | Error invalid -> Alcotest.failf "%s: %s" what (invalid_text invalid)

let is_invalid ?limits what expected bytes =
  match decide ?limits bytes with
  | Error invalid when expected invalid -> ()
  | other -> Alcotest.failf "%s: %s" what (decision_text other)

let within_seconds seconds what action =
  let start = Unix.gettimeofday () in
  let value = action () in
  let spent = Unix.gettimeofday () -. start in
  if spent > seconds then
    Alcotest.failf "%s took %.1f s, more than %.0f s" what spent seconds;
  value

let recognition_form = function
  | Response.Recognised -> ("recognised", `Assoc [])
  | Not_recognised -> ("not recognised", `Assoc [])
  | Recognition_failed error -> P.failed_form error

let binding_form = function
  | Response.Bound { results; bindings; warnings } ->
      ( "bound",
        `Assoc
          [
            ( "bindings",
              `List
                (List.map
                   (fun (binding : Response.binding) ->
                     `Assoc
                       [
                         ("reason", `String (P.text binding.reason));
                         ("result", `Int binding.result);
                         ("test", `String (P.text binding.test));
                       ])
                   bindings) );
            ("results", `List (List.map P.result_form results));
            ("warnings", `List (List.map (fun w -> `String (P.text w)) warnings));
          ] )
  | Bind_failed error -> P.failed_form error

let answer (result, values) =
  `Assoc [ ("result", `String result); ("values", values) ]

let adapters_set = P.adapters_set
let hex_member name input = W.of_hex (P.string (P.required name input))

let give_decision (vector : Vectors.vector) =
  let bytes = W.of_hex (P.string vector.input) in
  within_seconds 60. "the decision" (fun () ->
      `Assoc
        [
          ( "result",
            `String
              (match decide bytes with Ok _ -> "valid" | Error _ -> "invalid")
          );
        ])

(* @verifies packs#adapters[adapters][*]=v1
   The test decides each byte sequence of the group, under limits far above
   what its code needs, and compares "valid" or "invalid" with the result of
   the vector; the decision of the module that loops must end. *)
let adapter_vectors =
  Vectors.group adapters_set ~name:"adapters" ~form:"#adapter-vector=v1"
    give_decision

let ids_of input = List.map P.string (P.list (P.required "ids" input))

let call ?(limits = generous) ~function_ ~ids decision ~request ~content =
  match function_ with
  | `Recognise ->
      let outcome = Call.recognise ~limits decision ~request ~content in
      (recognition_form outcome.result, outcome.cause)
  | `Bind ->
      let outcome =
        Call.bind ~limits decision ~ids:(List.map P.text_of ids) ~request
          ~content
      in
      (binding_form outcome.result, outcome.cause)

let give_call (vector : Vectors.vector) =
  let input = vector.input in
  let function_, ids =
    match P.string (P.required "function" input) with
    | "recognise" -> (`Recognise, [])
    | _ -> (`Bind, ids_of input)
  in
  within_seconds 60. "the call" (fun () ->
      let decision = decide (hex_member "adapter" input) in
      answer
        (fst
           (call ~function_ ~ids decision
              ~request:(hex_member "request" input)
              ~content:(hex_member "report-content" input))))

(* @verifies packs#adapters[calls][*]=v1
   The test decides the adapter of each vector, makes the call with the
   function, the request bytes, the report content, and the test entry ids of
   the vector, under limits far above what its code needs, and compares the
   result and the values with those of the vector; the call whose function
   loops must end. *)
let call_vectors =
  Vectors.group adapters_set ~name:"calls" ~form:"#call-vector=v1" give_call

let import_of_each_kind =
  [
    ("a function", "(import \"env\" \"f\" (func))");
    ("a memory", "(import \"env\" \"m\" (memory 1))");
    ("a table", "(import \"env\" \"t\" (table 1 funcref))");
    ("a global", "(import \"env\" \"g\" (global i32))");
  ]

let memory_import = "(import \"env\" \"m\" (memory 1))"

let with_imports imports =
  if List.mem memory_import (String.split_on_char '\n' imports) then
    F.text ~imports ~memory:"" "(export \"memory\" (memory 0))"
  else F.text ~imports ""

let export_names =
  [
    "memory";
    "sinter_interface";
    "sinter_alloc";
    "sinter_recognise";
    "sinter_bind";
  ]

let adapter_with_exports exports =
  W.of_text
    (Printf.sprintf
       "(module (memory $m 1) (func $i (result i32) (i32.const 1)) (func $a \
        (param i32) (result i32) (i32.const 16)) (func $r (param i32 i32 i32 \
        i32) (result i64) (i64.const 0)) (func $wrong (param i32 i32 i32 i64) \
        (result i64) (i64.const 0)) (func $nothing) (table $t 1 funcref) \
        (global $g i32 (i32.const 1)) %s)"
       (String.concat " "
          (List.map
             (fun (name, item) -> Printf.sprintf "(export %S %s)" name item)
             exports)))

let right_exports =
  [
    ("memory", "(memory $m)");
    ("sinter_interface", "(func $i)");
    ("sinter_alloc", "(func $a)");
    ("sinter_recognise", "(func $r)");
    ("sinter_bind", "(func $r)");
  ]

let wrong_items =
  [
    ("memory", [ "(func $i)"; "(table $t)"; "(global $g)" ]);
    ( "sinter_interface",
      [ "(func $a)"; "(func $nothing)"; "(memory $m)"; "(global $g)" ] );
    ("sinter_alloc", [ "(func $i)"; "(func $r)"; "(table $t)" ]);
    ("sinter_recognise", [ "(func $wrong)"; "(func $a)"; "(global $g)" ]);
    ("sinter_bind", [ "(func $wrong)"; "(func $i)"; "(memory $m)" ]);
  ]

let interface_gives body = F.text ~interface:body ""
let loops = "(loop $l (br $l)) (i32.const 1)"

let decision_cases =
  [
    case "each feature of Core 2.0 is valid in an adapter" (fun () ->
        List.iter
          (fun (feature, bytes) -> is_valid feature bytes)
          F.core_2_features);
    (* @verifies packs#validate-adapters=v1
       Each byte sequence is a valid adapter but for one construct of a later
       proposal, so a decision that took a module beyond Core 2.0 as a
       WebAssembly module would give "valid". *)
    case "a construct of a later proposal makes an adapter invalid" (fun () ->
        List.iter
          (fun (proposal, bytes) ->
            is_invalid proposal
              (function Adapter.Not_a_module _ -> true | _ -> false)
              bytes)
          F.later_proposals);
    case "a module in the text format or a component is not a module" (fun () ->
        List.iter
          (fun (what, bytes) ->
            is_invalid what
              (function Adapter.Not_a_module _ -> true | _ -> false)
              bytes)
          [
            ( "the text of a valid adapter",
              "(module (memory (export \"memory\") 1) (func (export \
               \"sinter_interface\") (result i32) (i32.const 1)))" );
            ("a component", "\x00asm\x0d\x00\x01\x00");
            ("no byte", "");
          ]);
    (* @verifies packs#validate-adapters=v1
       A valid adapter has no import; an import of each kind, beside the five
       exports with their types, makes the decision "invalid". *)
    case "an import of each kind makes an adapter invalid" (fun () ->
        List.iter
          (fun (kind, import) ->
            is_invalid kind
              (function Adapter.Imports 1 -> true | _ -> false)
              (with_imports import))
          import_of_each_kind;
        is_invalid "four imports"
          (function Adapter.Imports 4 -> true | _ -> false)
          (with_imports (String.concat "\n" (List.map snd import_of_each_kind))));
    case "the five exports with their types make an adapter valid" (fun () ->
        is_valid "the five exports" (adapter_with_exports right_exports);
        is_valid "and other exports"
          (adapter_with_exports
             (right_exports
             @ [ ("__heap_base", "(global $g)"); ("t", "(table $t)") ])));
    (* @verifies packs#validate-adapters=v1
       Each of the five names, missing, makes the decision "invalid", so a
       decision that left out the check of one export would give "valid". *)
    case "each missing export makes an adapter invalid" (fun () ->
        List.iter
          (fun name ->
            is_invalid name
              (function Adapter.Missing_export n -> n = name | _ -> false)
              (adapter_with_exports (List.remove_assoc name right_exports)))
          export_names);
    (* @verifies packs#validate-adapters=v1
       Each of the five names, exported as another kind or as a function of
       another type, makes the decision "invalid". *)
    case "each export of the wrong kind or type makes an adapter invalid"
      (fun () ->
        List.iter
          (fun (name, items) ->
            List.iter
              (fun item ->
                is_invalid
                  (name ^ " as " ^ item)
                  (function Adapter.Wrong_export n -> n = name | _ -> false)
                  (adapter_with_exports
                     ((name, item) :: List.remove_assoc name right_exports)))
              items)
          wrong_items);
    case "the first condition that fails gives the reason" (fun () ->
        is_invalid "an import and no export"
          (function Adapter.Imports 1 -> true | _ -> false)
          (W.of_text "(module (import \"env\" \"f\" (func)))");
        is_invalid "no memory and no sinter_bind"
          (function Adapter.Missing_export "memory" -> true | _ -> false)
          (adapter_with_exports
             (List.filter
                (fun (name, _) -> name <> "memory" && name <> "sinter_bind")
                right_exports));
        is_invalid "sinter_alloc wrong and sinter_recognise missing"
          (function Adapter.Wrong_export "sinter_alloc" -> true | _ -> false)
          (adapter_with_exports
             (("sinter_alloc", "(func $i)")
             :: List.remove_assoc "sinter_alloc"
                  (List.remove_assoc "sinter_recognise" right_exports)));
        is_invalid "sinter_bind missing and the interface traps"
          (function Adapter.Missing_export "sinter_bind" -> true | _ -> false)
          (W.of_text
             "(module (memory (export \"memory\") 1) (func (export \
              \"sinter_interface\") (result i32) unreachable) (func (export \
              \"sinter_alloc\") (param i32) (result i32) (i32.const 16)) (func \
              (export \"sinter_recognise\") (param i32 i32 i32 i32) (result \
              i64) (i64.const 0)))"));
    case "a version other than 1 makes an adapter invalid" (fun () ->
        List.iter
          (fun version ->
            is_invalid (Int32.to_string version)
              (function
                | Adapter.Interface_version v -> v = version | _ -> false)
              (interface_gives (Printf.sprintf "(i32.const %ld)" version)))
          [ 0l; 2l; -1l; 257l; Int32.min_int ]);
    case "an instantiation that fails makes an adapter invalid" (fun () ->
        let trap = function
          | Adapter.Instantiation_failed (Trap _) -> true
          | _ -> false
        in
        is_invalid "a start function that traps" trap
          (F.text "(func $s unreachable) (start $s)");
        is_invalid "data outside the memory" trap
          (F.text "(data (i32.const 65530) \"0123456789\")");
        is_invalid "elements outside the table" trap
          (F.text "(table 1 funcref) (elem (i32.const 1) func $s) (func $s)"));
    (* @verifies packs#end-adapter-code=v1
       Code that never ends, in the start function or in sinter_interface,
       must end in the decision; with small limits the decision ends at once
       and gives "invalid". *)
    case "the decision ends code that never ends" (fun () ->
        within_seconds 30. "the decisions" (fun () ->
            is_invalid ~limits:small "a loop in sinter_interface"
              (function
                | Adapter.Interface_failed (Stopped Fuel) -> true | _ -> false)
              (interface_gives loops);
            is_invalid ~limits:small "a loop in the start function"
              (function
                | Adapter.Instantiation_failed (Stopped Fuel) -> true
                | _ -> false)
              (F.text "(func $s (loop $l (br $l))) (start $s)");
            is_invalid ~limits:small "a loop of bulk instructions"
              (function
                | Adapter.Interface_failed (Stopped Fuel) -> true | _ -> false)
              (F.text ~memory:"(memory 16)"
                 ~interface:
                   "(loop $l (memory.fill (i32.const 0) (i32.const 7) \
                    (i32.const 1048576)) (br $l)) (i32.const 1)"
                 "");
            is_invalid "a recursion that never ends"
              (function
                | Adapter.Interface_failed Stack_exhausted -> true | _ -> false)
              (F.text ~interface:"(call $r)" "(func $r (result i32) (call $r))");
            is_invalid "a loop under the limits of the vectors"
              (function Adapter.Interface_failed _ -> true | _ -> false)
              (interface_gives loops)));
    case "a stop at a limit gives invalid" (fun () ->
        is_invalid ~limits:small "a memory past the limit"
          (function
            | Adapter.Instantiation_failed (Stopped Memory) -> true | _ -> false)
          (F.text ~memory:"(memory 32)" "");
        is_invalid ~limits:small "a table past the limit"
          (function
            | Adapter.Instantiation_failed (Stopped Table) -> true | _ -> false)
          (F.text "(table 5000 funcref)");
        is_invalid ~limits:small "a growth past the limit"
          (function
            | Adapter.Interface_failed (Stopped Memory) -> true | _ -> false)
          (interface_gives "(drop (memory.grow (i32.const 100))) (i32.const 1)"));
    (* @verifies packs#validate-adapters=v1
       A growth past the maximum of a memory or a table is not a choice of the
       program: memory.grow and table.grow give -1 and the code goes on, so,
       when the program stops none of its code, the adapter is valid.
       sinter_interface gives 1 only when the growth gave -1. *)
    case "a growth past the maximum gives -1 and the adapter stays valid"
      (fun () ->
        List.iter
          (fun (what, memory, rest, growth) ->
            is_valid what
              (F.text ~memory
                 ~interface:(Printf.sprintf "(i32.eq %s (i32.const -1))" growth)
                 rest))
          [
            ( "a memory of at most 2 pages",
              "(memory 1 2)",
              "",
              "(memory.grow (i32.const 2))" );
            ( "a memory with no maximum",
              "(memory 1)",
              "",
              "(memory.grow (i32.const 65536))" );
            ( "a memory by 2^32 - 1 pages",
              "(memory 1)",
              "",
              "(memory.grow (i32.const -1))" );
            ( "a table of at most 3 elements",
              "(memory 1)",
              "(table 1 3 funcref)",
              "(table.grow (ref.null func) (i32.const 3))" );
            ( "a table with no maximum",
              "(memory 1)",
              "(table 1 externref)",
              "(table.grow (ref.null extern) (i32.const -1))" );
          ]);
    property ~count:300 "the decision agrees with the reference interpreter"
      Wasm_gen.module_text
      ~print:(fun text -> text)
      (fun text ->
        let bytes = W.of_text_unchecked text in
        match (W.reference_decision bytes, decide bytes) with
        | W.Valid, Ok _ | W.Invalid, Error _ | W.Unknown, _ -> true
        | W.Valid, Error invalid ->
            QCheck2.Test.fail_reportf "invalid (%s), but the reference: valid"
              (invalid_text invalid)
        | W.Invalid, Ok _ ->
            QCheck2.Test.fail_reportf "valid, but the reference: invalid");
    property ~count:300
      "a corrupted adapter is invalid when the reference refuses it"
      Gen.(
        triple Wasm_gen.module_text
          (list_size (int_range 1 4) (pair nat (int_bound 255)))
          (option nat))
      ~print:(fun (text, flips, cut) ->
        Printf.sprintf "%s\nflips %s, cut %s" text
          (String.concat " "
             (List.map (fun (a, b) -> Printf.sprintf "%d:%d" a b) flips))
          (match cut with Some n -> string_of_int n | None -> "none"))
      (fun (text, flips, cut) ->
        let bytes = Bytes.of_string (W.of_text_unchecked text) in
        List.iter
          (fun (place, value) ->
            Bytes.set bytes (place mod Bytes.length bytes) (Char.chr value))
          flips;
        let bytes = Bytes.to_string bytes in
        let bytes =
          match cut with
          | Some n -> String.sub bytes 0 (n mod String.length bytes)
          | None -> bytes
        in
        let decision =
          within_seconds 30. "the decision" (fun () ->
              decide ~limits:small bytes)
        in
        match (W.reference bytes, decision) with
        | W.Refused _, Ok _ ->
            QCheck2.Test.fail_reportf "valid, but the reference refuses it"
        | _ -> true);
    property ~count:100 "other limits change a decision only by a stop"
      Wasm_gen.module_text
      ~print:(fun text -> text)
      (fun text ->
        let bytes = W.of_text_unchecked text in
        let tight = limits ~fuel:300 ~memory:65_536 ~table:2 in
        match (decide bytes, decide ~limits:tight bytes) with
        | Ok _, Ok _ | Error _, Error _ -> true
        | ( Ok _,
            Error
              (Instantiation_failed (Stopped _) | Interface_failed (Stopped _))
          ) ->
            true
        | Error invalid, Ok _ ->
            QCheck2.Test.fail_reportf "valid only under tight limits: %s"
              (invalid_text invalid)
        | Ok _, Error invalid ->
            QCheck2.Test.fail_reportf "tight limits gave: %s"
              (invalid_text invalid));
    case "a valid adapter keeps its compiled module" (fun () ->
        match decide (F.text "") with
        | Error invalid -> Alcotest.fail (invalid_text invalid)
        | Ok adapter ->
            let names =
              List.map fst (Wasm_module.exports (Adapter.compiled adapter))
            in
            Alcotest.(check (list string))
              "the exports"
              (List.sort compare export_names)
              (List.sort compare names));
    property ~count:500 "the decision never raises" Gen.string ~print:W.hex
      (fun bytes ->
        match decide ~limits:small bytes with Ok _ | Error _ -> true);
  ]

let truth = {|{"recognised":true}|}
let falsity = {|{"recognised":false}|}

let yes_no =
  Printf.sprintf "(data (i32.const 64) %s) (data (i32.const 512) %s)"
    (F.data_string truth) (F.data_string falsity)

let answer_if condition =
  Printf.sprintf "(if (result i64) %s (then %s) (else %s))" condition
    (F.pointer "(i32.const 64)" "(i32.const 19)")
    (F.pointer "(i32.const 512)" "(i32.const 20)")

let conjunction = function
  | [] -> "(i32.const 1)"
  | first :: rest ->
      List.fold_left
        (fun acc c -> Printf.sprintf "(i32.and %s %s)" acc c)
        first rest

let recognises = answer_if "(i32.const 1)"

let two_allocs first second =
  Printf.sprintf
    "(global.set $k (i32.add (global.get $k) (i32.const 1))) (if (result i32) \
     (i32.eq (global.get $k) (i32.const 1)) (then %s) (else %s))"
    first second

let with_allocs ?(memory = "(memory 1)") ?(recognise = recognises) first second
    =
  F.text ~memory ~alloc:(two_allocs first second) ~recognise
    ("(global $k (mut i32) (i32.const 0)) " ^ yes_no)

let bump_adapter ?(memory = "(memory 1)") ?(rest = "") recognise =
  F.text ~memory ~alloc:"(call $bump (local.get $n))" ~recognise
    (String.concat " " [ F.bump; yes_no; rest ])

let request = "0123456789"
let content = "abcde"

let recognise ?(limits = generous) ?(request = request) ?(content = content)
    bytes =
  Call.recognise ~limits (decide bytes) ~request ~content

let bind ?(limits = generous) ?(ids = []) ?(request = request)
    ?(content = content) bytes =
  Call.bind ~limits (decide bytes) ~ids:(List.map P.text_of ids) ~request
    ~content

let part_text = function
  | Call.Request -> "the request"
  | Report_content -> "the report content"
  | Response -> "the response"

let cause_text = function
  | None -> "no cause"
  | Some (Call.Too_long part) -> part_text part ^ " is too long"
  | Some (Not_valid invalid) -> "not valid: " ^ invalid_text invalid
  | Some (Failed _) -> "a step failed"
  | Some (Zero_address part) -> "the address 0 for " ^ part_text part
  | Some (Outside_memory part) -> part_text part ^ " outside the memory"

let recognition_text result = fst (recognition_form result)

let expect what ~result ~cause (outcome : Response.recognition Call.outcome) =
  if outcome.result <> result || not (cause outcome.cause) then
    Alcotest.failf "%s: %s with %s" what
      (recognition_text outcome.result)
      (cause_text outcome.cause)

let fails_before_response what cause outcome =
  expect what ~result:(Response.Recognition_failed None)
    ~cause:(fun c -> c = Some cause)
    outcome

let fails_in_a_step what step outcome =
  expect what ~result:(Response.Recognition_failed None)
    ~cause:(function Some (Call.Failed failure) -> step failure | _ -> false)
    outcome

let recognised what outcome =
  expect what ~result:Response.Recognised ~cause:(( = ) None) outcome

let end_minus = Printf.sprintf "(i32.sub (i32.const %d) (local.get $n))"

(* @verifies packs#give-call-results=v1
   Each address that sinter_alloc gives is checked as the design states it:
   0 fails, an address whose bytes pass the end of the memory fails, and an
   address whose bytes end exactly at the end of the memory does not; with the
   address taken as unsigned, so -16 is far past the end. *)
let address_cases =
  [
    case "the address 0 for the request or the report content fails" (fun () ->
        fails_before_response "the request" (Call.Zero_address Request)
          (recognise (with_allocs "(i32.const 0)" "(i32.const 1024)"));
        fails_before_response "the report content"
          (Call.Zero_address Report_content)
          (recognise (with_allocs "(i32.const 1024)" "(i32.const 0)")));
    case "bytes that end at the end of the memory lie inside it" (fun () ->
        recognised "the request at the end"
          (recognise (with_allocs (end_minus 65536) "(i32.const 1024)"));
        recognised "the report content at the end"
          (recognise (with_allocs "(i32.const 1024)" (end_minus 65536)));
        recognised "an empty request at the end"
          (recognise ~request:""
             (with_allocs "(i32.const 65536)" "(i32.const 1024)"));
        recognised "an empty report content at the end"
          (recognise ~content:""
             (with_allocs "(i32.const 1024)" "(i32.const 65536)")));
    case "bytes past the end of the memory fail" (fun () ->
        fails_before_response "the request" (Call.Outside_memory Request)
          (recognise (with_allocs (end_minus 65537) "(i32.const 1024)"));
        fails_before_response "the report content"
          (Call.Outside_memory Report_content)
          (recognise (with_allocs "(i32.const 1024)" (end_minus 65537)));
        fails_before_response "an empty request past the end"
          (Call.Outside_memory Request)
          (recognise ~request:""
             (with_allocs "(i32.const 65537)" "(i32.const 1024)"));
        fails_before_response "a request longer than the memory"
          (Call.Outside_memory Request)
          (recognise ~request:(String.make 70_000 'x')
             (with_allocs "(i32.const 16)" "(i32.const 1024)")));
    case "a request or a report content of 2^32 bytes or more is too long"
      (fun () ->
        List.iter
          (fun (length, expected) ->
            Alcotest.(check bool)
              (Printf.sprintf "%d bytes" length)
              expected (Call.too_long length))
          [
            (0, false);
            ((1 lsl 32) - 1, false);
            (1 lsl 32, true);
            ((1 lsl 32) + 1, true);
            (max_int, true);
          ]);
    case "an address is unsigned" (fun () ->
        fails_before_response "the request at 2^32 - 16"
          (Call.Outside_memory Request)
          (recognise (with_allocs "(i32.const -16)" "(i32.const 1024)"));
        fails_before_response "the report content at 2^31"
          (Call.Outside_memory Report_content)
          (recognise (with_allocs "(i32.const 1024)" "(i32.const -2147483648)")));
    case "the bytes of a request in a grown memory lie inside it" (fun () ->
        recognised "the request in the second page"
          (recognise
             (with_allocs ~memory:"(memory 1 2)"
                "(if (result i32) (i32.eq (memory.grow (i32.const 1)) \
                 (i32.const 1)) (then (i32.const 65536)) (else (i32.const \
                 16)))"
                "(i32.const 1024)")));
  ]

let response_at address length = F.pointer address length

(* @verifies packs#give-call-results=v1
   The response is the length bytes from the address that the function gives,
   both unsigned, and the call fails exactly when they pass the end of the
   memory, as the size of the memory is when the step reads it. *)
let response_cases =
  [
    case "a response that ends at the end of the memory is read" (fun () ->
        recognised "at the end"
          (recognise
             (bump_adapter
                ~rest:
                  (Printf.sprintf "(data (i32.const 65517) %s)"
                     (F.data_string truth))
                (response_at "(i32.const 65517)" "(i32.const 19)"))));
    case "a response at the address 0 is read" (fun () ->
        recognised "at 0"
          (recognise
             (bump_adapter
                ~rest:
                  (Printf.sprintf "(data (i32.const 0) %s)"
                     (F.data_string truth))
                (response_at "(i32.const 0)" "(i32.const 19)"))));
    case "an empty response at the end of the memory is no failure before it"
      (fun () ->
        expect "an empty response" ~result:(Response.Recognition_failed None)
          ~cause:(( = ) None)
          (recognise
             (bump_adapter (response_at "(i32.const 65536)" "(i32.const 0)"))));
    case "a response past the end of the memory fails" (fun () ->
        List.iter
          (fun (what, address, length) ->
            fails_before_response what (Call.Outside_memory Response)
              (recognise (bump_adapter (response_at address length))))
          [
            ("one byte past", "(i32.const 65518)", "(i32.const 19)");
            ( "an empty response past the end",
              "(i32.const 65537)",
              "(i32.const 0)" );
            ("at 2^32 - 16", "(i32.const -16)", "(i32.const 19)");
            ("2^32 - 1 bytes", "(i32.const 0)", "(i32.const -1)");
            ("2^31 bytes", "(i32.const 16)", "(i32.const -2147483648)");
          ]);
    case "a response in a grown memory is read" (fun () ->
        let outcome =
          recognise
            (bump_adapter ~memory:"(memory 1 2)"
               "(if (result i64) (i32.eq (memory.grow (i32.const 1)) \
                (i32.const 1)) (then (memory.copy (i32.const 65536) (i32.const \
                64) (i32.const 19)) (i64.or (i64.shl (i64.const 65536) \
                (i64.const 32)) (i64.const 19))) (else (i64.or (i64.shl \
                (i64.const 512) (i64.const 32)) (i64.const 20))))")
        in
        match (outcome.result, outcome.cause) with
        | (Recognised | Not_recognised), None -> ()
        | result, cause ->
            Alcotest.failf "%s with %s" (recognition_text result)
              (cause_text cause));
  ]

let trap = function Instance.Trap _ -> true | _ -> false
let stopped limit = function Instance.Stopped l -> l = limit | _ -> false

(* @verifies packs#give-call-results=v1
   A failure of the instantiation or of an invocation of a step fails the
   call, with "failed" and no error text. *)
let step_cases =
  [
    case "a trap in sinter_alloc fails the call" (fun () ->
        fails_in_a_step "the first" trap
          (recognise (with_allocs "(unreachable)" "(i32.const 1024)"));
        fails_in_a_step "the second" trap
          (recognise (with_allocs "(i32.const 1024)" "(unreachable)")));
    case "a trap in the function fails the call" (fun () ->
        fails_in_a_step "recognise" trap
          (recognise (bump_adapter "(unreachable)"));
        match (bind (F.text ~bind:"(unreachable)" "")).result with
        | Bind_failed None -> ()
        | other -> Alcotest.failf "bind: %s" (fst (binding_form other)));
    (* @verifies packs#end-adapter-code=v1
       Code of a call that never ends, in sinter_alloc or in the function, must
       end; with small limits the call ends at once and fails. *)
    case "a call ends code that never ends" (fun () ->
        within_seconds 30. "the calls" (fun () ->
            fails_in_a_step "a loop in sinter_alloc" (stopped Fuel)
              (recognise ~limits:small
                 (with_allocs "(loop $l (br $l)) (i32.const 16)"
                    "(i32.const 1024)"));
            fails_in_a_step "a loop in the second sinter_alloc" (stopped Fuel)
              (recognise ~limits:small
                 (with_allocs "(i32.const 16)"
                    "(loop $l (br $l)) (i32.const 1024)"));
            fails_in_a_step "a loop in recognise" (stopped Fuel)
              (recognise ~limits:small
                 (bump_adapter "(loop $l (br $l)) (i64.const 0)"));
            fails_in_a_step "a recursion in recognise"
              (function Instance.Stack_exhausted -> true | _ -> false)
              (recognise
                 (bump_adapter ~rest:"(func $r (result i64) (call $r))"
                    "(call $r)"));
            fails_in_a_step "a growth past the limit" (stopped Memory)
              (recognise ~limits:small
                 (bump_adapter
                    "(drop (memory.grow (i32.const 100))) (i64.const 0)"));
            match
              (bind ~limits:small
                 (F.text ~bind:"(loop $l (br $l)) (i64.const 0)" ""))
                .result
            with
            | Bind_failed None -> ()
            | other ->
                Alcotest.failf "a loop in bind: %s" (fst (binding_form other))));
    (* @verifies packs#end-adapter-code=v1
       A recursion without end, in a decision and in a call, on the main thread
       and on the thread of a Domain, whose own stack can be smaller than the
       stack of the engine, must end with "invalid" and "failed", and the
       process must live. *)
    case "a recursion without end ends on any thread" (fun () ->
        let deep =
          F.text ~interface:"(call $i)" ~alloc:"(call $bump (local.get $n))"
            ~recognise:"(call $r)"
            (F.bump
           ^ " (func $i (result i32) (call $i)) (func $r (result i64) (call \
              $r))")
        in
        let calls_back =
          bump_adapter ~rest:"(func $r (result i64) (call $r))" "(call $r)"
        in
        let run () =
          List.iter
            (fun stack ->
              match Engine.create ~stack with
              | Error (Not_made message) -> Alcotest.fail message
              | Ok engine ->
                  (match Adapter.decide ~limits:generous engine deep with
                  | Error (Interface_failed Stack_exhausted) -> ()
                  | other ->
                      Alcotest.failf "the decision: %s" (decision_text other));
                  fails_in_a_step "the call"
                    (function Instance.Stack_exhausted -> true | _ -> false)
                    (Call.recognise ~limits:generous
                       (Adapter.decide ~limits:generous engine calls_back)
                       ~request ~content))
            [ 524_288; 2_097_152 ]
        in
        run ();
        Domain.join (Domain.spawn run));
    case "a stop of the instantiation of the call fails the call" (fun () ->
        List.iter
          (fun (what, bytes, limit) ->
            let decision = decide bytes in
            (match decision with
            | Ok _ -> ()
            | Error invalid ->
                Alcotest.failf "%s: %s" what (invalid_text invalid));
            fails_in_a_step what (stopped limit)
              (Call.recognise ~limits:small decision ~request ~content);
            let bound =
              Call.bind ~limits:small decision ~ids:[] ~request ~content
            in
            match (bound.result, bound.cause) with
            | Bind_failed None, Some (Failed (Stopped l)) when l = limit -> ()
            | result, cause ->
                Alcotest.failf "%s, bind: %s with %s" what
                  (fst (binding_form result))
                  (cause_text cause))
          [
            ( "a memory of 32 pages",
              F.text ~memory:"(memory 32)" "",
              Instance.Memory );
            ( "a table of 5,000 elements",
              F.text "(table 5000 funcref)",
              Instance.Table );
          ]);
    case "an adapter that is not valid in the decision fails the call"
      (fun () ->
        let bytes = interface_gives "(i32.const 2)" in
        let decision = decide bytes in
        let outcome =
          Call.recognise ~limits:generous decision ~request ~content
        in
        match (decision, outcome.cause) with
        | Error invalid, Some (Not_valid reason) when invalid = reason ->
            expect "recognise" ~result:(Recognition_failed None)
              ~cause:(fun _ -> true)
              outcome
        | _ -> Alcotest.failf "the call: %s" (cause_text outcome.cause));
    case "a growth past the maximum in a call gives -1, and the call goes on"
      (fun () ->
        recognised "memory.grow"
          (recognise
             (bump_adapter ~memory:"(memory 1 2)"
                (answer_if "(i32.eq (memory.grow (i32.const 5)) (i32.const -1))"))));
  ]

let error_response = {|{"error":"the report is broken"}|}

(* @verifies packs#{omit-adapter-error-texts=v1, omit-call-values=v1}
   A call gives the error text of the adapter only when its response gives
   one, and a failure before a response gives no error text and no values. *)
let error_cases =
  [
    case "the error text of a response is the error text of the call" (fun () ->
        let outcome = recognise (F.responds error_response) in
        expect "recognise"
          ~result:(Recognition_failed (Some (P.text_of "the report is broken")))
          ~cause:(( = ) None) outcome;
        let bound = bind (F.responds error_response) in
        match (bound.result, bound.cause) with
        | Bind_failed (Some text), None
          when P.text text = "the report is broken" ->
            ()
        | other, cause ->
            Alcotest.failf "bind: %s with %s"
              (fst (binding_form other))
              (cause_text cause));
    case "a failure before a response gives no error text and no values"
      (fun () ->
        let failing = with_allocs "(i32.const 0)" "(i32.const 1024)" in
        (match (bind ~ids:[ "t1" ] failing).result with
        | Bind_failed None -> ()
        | other -> Alcotest.failf "bind: %s" (fst (binding_form other)));
        match (recognise failing).result with
        | Recognition_failed None -> ()
        | other -> Alcotest.failf "recognise: %s" (recognition_text other));
  ]

let reference_form = function
  | `Recognise -> Adapter_reference.Recognise
  | `Bind ids -> Adapter_reference.Bind ids

let echo_matches function_ ~request ~content =
  let expected =
    Adapter_reference.response (reference_form function_) content
  in
  let given, cause =
    match function_ with
    | `Recognise ->
        call ~function_:`Recognise ~ids:[] (decide F.echo) ~request ~content
    | `Bind ids -> call ~function_:`Bind ~ids (decide F.echo) ~request ~content
  in
  match cause with
  | Some _ ->
      QCheck2.Test.fail_reportf "a failure before the response: %s"
        (cause_text cause)
  | None ->
      (fst given = fst expected && Vectors.equal_json (snd given) (snd expected))
      || QCheck2.Test.fail_reportf "gave %s %s, the design gives %s %s"
           (fst given)
           (Yojson.Basic.to_string (snd given))
           (fst expected)
           (Yojson.Basic.to_string (snd expected))

let response_vector_through_calls () =
  List.iter
    (fun (vector : Vectors.vector) ->
      let input = vector.input in
      let content = hex_member "response" input in
      let function_, ids =
        match P.string (P.required "function" input) with
        | "recognise" -> (`Recognise, [])
        | _ -> (`Bind, ids_of input)
      in
      let (result, values), cause =
        call ~function_ ~ids (decide F.echo) ~request ~content
      in
      let expected_result = Option.value vector.result ~default:"" in
      let expected_values = Option.value vector.values ~default:(`Assoc []) in
      if
        cause <> None || result <> expected_result
        || not (Vectors.equal_json values expected_values)
      then
        Alcotest.failf "line %d: %s %s with %s" vector.line result
          (Yojson.Basic.to_string values)
          (cause_text cause))
    (Vectors.vectors adapters_set "responses")

let bytes_gen = Gen.string_size ~gen:Gen.char (Gen.int_bound 2_000)

(* @verifies packs#{give-call-results=v1, give-call-values=v1}
   The adapter gives back its report content as its response, so the result
   and the values of the call must be those that the design gives for that
   response, for each response of the group responses and for generated
   ones. *)
let value_cases =
  [
    case
      "the responses of the group responses give their results through a call"
      response_vector_through_calls;
    property ~count:200 "a call gives the result and the values of its response"
      Gen.(
        pair bytes_gen
          (oneof
             [
               P.response_gen;
               map (fun bytes -> (Adapter_reference.Recognise, bytes)) bytes_gen;
             ]))
      (fun (request, (function_, content)) ->
        let function_ =
          match function_ with
          | Adapter_reference.Recognise -> `Recognise
          | Bind ids -> `Bind ids
        in
        echo_matches function_ ~request ~content);
  ]

let counting =
  lazy
    (F.text
       ~interface:
         "(global.set $count (i32.add (global.get $count) (i32.const 1))) \
          (i32.store8 (i32.const 100) (i32.const 1)) (i32.const 1)"
       ~alloc:"(call $bump (local.get $n))"
       ~recognise:
         ("(global.set $count (i32.add (global.get $count) (i32.const 1))) "
         ^ answer_if
             (conjunction
                [
                  "(i32.eq (global.get $count) (i32.const 1))";
                  "(i32.eqz (i32.load8_u (i32.const 100)))";
                  "(i32.eq (global.get $starts) (i32.const 1))";
                ]))
       (String.concat " "
          [
            F.bump;
            yes_no;
            "(global $count (mut i32) (i32.const 0)) (global $starts (mut i32) \
             (i32.const 0)) (func $start (global.set $starts (i32.add \
             (global.get $starts) (i32.const 1)))) (start $start)";
          ]))

(* @verifies packs#isolate-adapters=v1
   The adapter counts the invocations of its functions in a global and marks
   its memory in sinter_interface; recognise gives true only when it is the
   first invocation of its instance after one run of the start function, and
   the memory holds no mark. So the call must run in a new instance, not in the
   instance of the decision nor of an earlier call. *)
let isolation_cases =
  [
    case "each call runs in a new instance of its own" (fun () ->
        let decision = decide (Lazy.force counting) in
        List.iter
          (fun n ->
            recognised
              (Printf.sprintf "call %d" n)
              (Call.recognise ~limits:generous decision ~request ~content))
          [ 1; 2; 3 ]);
  ]

let steps_adapter =
  lazy
    (F.text
       ~alloc:
         "(global.set $calls (i32.add (global.get $calls) (i32.const 1))) (if \
          (result i32) (i32.eq (global.get $calls) (i32.const 1)) (then \
          (global.set $n1 (local.get $n)) (global.set $a1 (call $bump \
          (local.get $n))) (global.get $a1)) (else (global.set $n2 (local.get \
          $n)) (global.set $s1 (call $sum (global.get $a1) (global.get $n1))) \
          (global.set $a2 (call $bump (local.get $n))) (global.get $a2)))"
       ~recognise:
         (answer_if
            (conjunction
               [
                 "(i32.eq (global.get $calls) (i32.const 2))";
                 "(i32.eq (global.get $n1) (local.get $rn))";
                 "(i32.eq (global.get $n2) (local.get $cn))";
                 "(i32.eq (global.get $a1) (local.get $ra))";
                 "(i32.eq (global.get $a2) (local.get $ca))";
                 "(i32.eq (global.get $s1) (call $sum (local.get $ra) \
                  (local.get $rn)))";
                 "(call $plain (i32.const 2048) (local.get $ra))";
                 "(call $plain (i32.add (local.get $ra) (local.get $rn)) \
                  (local.get $ca))";
                 "(call $plain (i32.add (local.get $ca) (local.get $cn)) \
                  (i32.add (i32.add (local.get $ca) (local.get $cn)) \
                  (i32.const 8)))";
               ]))
       (String.concat " "
          [
            F.bump;
            yes_no;
            "(global $calls (mut i32) (i32.const 0)) (global $n1 (mut i32) \
             (i32.const -1)) (global $n2 (mut i32) (i32.const -1)) (global $a1 \
             (mut i32) (i32.const 0)) (global $a2 (mut i32) (i32.const 0)) \
             (global $s1 (mut i32) (i32.const 0))";
            Printf.sprintf "(data (i32.const 2048) %s)"
              (F.data_string (String.make 8192 '\x5a'));
            "(func $plain (param $from i32) (param $to i32) (result i32) \
             (block $no (loop $next (br_if $no (i32.ge_u (local.get $from) \
             (local.get $to))) (if (i32.ne (i32.load8_u (local.get $from)) \
             (i32.const 0x5a)) (then (return (i32.const 0)))) (local.set $from \
             (i32.add (local.get $from) (i32.const 1))) (br $next))) \
             (i32.const 1))";
            "(func $sum (param $from i32) (param $n i32) (result i32) (local \
             $s i32) (local $i i32) (block $done (loop $next (br_if $done \
             (i32.ge_u (local.get $i) (local.get $n))) (local.set $s (i32.add \
             (i32.mul (local.get $s) (i32.const 31)) (i32.load8_u (i32.add \
             (local.get $from) (local.get $i))))) (local.set $i (i32.add \
             (local.get $i) (i32.const 1))) (br $next))) (local.get $s))";
          ]))

(* @verifies packs#give-call-results=v1
   The adapter records the steps of the call: recognise gives true only when
   sinter_alloc ran twice, first for the number of bytes of the request and
   then for those of the report content, when the request was in the memory
   before the second invocation, when the function got the two addresses and
   the two numbers of bytes, and when the bytes around the two writes are as
   the module left them. *)
let step_order_cases =
  [
    property ~count:100
      "a call runs the steps in their order and writes only its parts"
      Gen.(pair bytes_gen bytes_gen)
      ~print:(fun (r, c) -> W.hex r ^ " " ^ W.hex c)
      (fun (request, content) ->
        let outcome =
          Call.recognise ~limits:generous
            (decide (Lazy.force steps_adapter))
            ~request ~content
        in
        (outcome.result = Recognised && outcome.cause = None)
        || QCheck2.Test.fail_reportf "%s with %s"
             (recognition_text outcome.result)
             (cause_text outcome.cause));
  ]

let request_of_vector input =
  let runner = P.runner_of (P.string (P.required "runner" input)) in
  let settings = P.settings_of (P.required "settings" input) in
  let report = P.text_of (P.string (P.required "report" input)) in
  (runner, settings, report)

let entry json = P.entry_of (Yojson.Basic.from_string json)

let entry_json id =
  Printf.sprintf
    {|{"id":%S,"path":"a.ts","line":1,"eline":2,"suite":false,"names":[[{"text":"adds"}]],"labels":[]}|}
    id

let one_binding =
  {|{"bindings":[{"reason":"name","result":0,"test":"t1"}],"results":[{"name":"adds","status":"pass"}],"warnings":[]}|}

(* @verifies packs#give-requests=v1
   For the things of each vector of the group requests, the adapter gives
   "recognised" or "bound" only when the request in its memory is exactly the
   request of the vector, so the call must write the request that the design
   gives, and no other bytes. *)
let request_cases =
  [
    case "a call through the request writes the request of its things"
      (fun () ->
        List.iter
          (fun (vector : Vectors.vector) ->
            let input = vector.input in
            let expected =
              match vector.values with
              | Some values -> P.string (P.required "request" values)
              | None -> Alcotest.fail "a vector with no request"
            in
            let decision = decide (F.request_is expected) in
            let runner, settings, report = request_of_vector input in
            match P.string (P.required "function" input) with
            | "recognise" ->
                recognised
                  (Printf.sprintf "line %d" vector.line)
                  (Call.recognise_request ~limits:generous decision ~runner
                     ~settings ~report ~content)
            | _ -> (
                let entries =
                  List.map P.entry_of (P.list (P.required "tests" input))
                in
                match
                  Call.bind_request ~limits:generous decision ~runner ~settings
                    ~report
                    ~root:(P.text_of (P.string (P.required "root" input)))
                    entries ~content
                with
                | Ok { result = Bound _; cause = None } -> ()
                | Ok { result; cause } ->
                    Alcotest.failf "line %d: %s with %s" vector.line
                      (fst (binding_form result))
                      (cause_text cause)
                | Error _ -> Alcotest.failf "line %d: no request" vector.line))
          (Vectors.vectors adapters_set "requests"));
    case "another request is not the request of the adapter" (fun () ->
        let runner = P.runner_of "vitest" in
        let settings = P.settings_of (`Assoc []) in
        let request =
          Request.recognise ~runner ~settings ~report:(P.text_of "a.xml")
        in
        let decision = decide (F.request_is (request ^ " ")) in
        expect "a request with one more byte" ~result:Not_recognised
          ~cause:(( = ) None)
          (Call.recognise_request ~limits:generous decision ~runner ~settings
             ~report:(P.text_of "a.xml") ~content));
    case "a call of bind through the request takes the ids of its test entries"
      (fun () ->
        let runner = P.runner_of "vitest" in
        let settings = P.settings_of (`Assoc []) in
        let call entries =
          Call.bind_request ~limits:generous
            (decide (F.responds one_binding))
            ~runner ~settings ~report:(P.text_of "a.xml") ~root:(P.text_of "/r")
            entries ~content
        in
        (match call [ entry (entry_json "t2"); entry (entry_json "t1") ] with
        | Ok { result = Bound { bindings = [ b ]; _ }; cause = None }
          when P.text b.test = "t1" ->
            ()
        | Ok { result; _ } ->
            Alcotest.failf "with t1: %s" (fst (binding_form result))
        | Error _ -> Alcotest.fail "with t1: no request");
        (match call [ entry (entry_json "t2") ] with
        | Ok { result = Bind_failed None; cause = None } -> ()
        | Ok { result; _ } ->
            Alcotest.failf "without t1: %s" (fst (binding_form result))
        | Error _ -> Alcotest.fail "without t1: no request");
        match call [ entry (entry_json "t1"); entry (entry_json "t1") ] with
        | Error (Request.Repeated_id _) -> ()
        | Ok _ -> Alcotest.fail "two test entries with one id gave a call");
  ]

let tests =
  Vectors.tests "packs.adapters" [ adapter_vectors; call_vectors ]
  @ decision_cases @ address_cases @ response_cases @ step_cases @ error_cases
  @ value_cases @ isolation_cases @ step_order_cases @ request_cases
