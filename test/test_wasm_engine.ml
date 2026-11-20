(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_wasm_engine
module W = Wasm_modules
module Gen = QCheck2.Gen

let engine =
  lazy
    (match Engine.create ~stack:524_288 with
    | Ok engine -> engine
    | Error (Not_made message) -> Alcotest.failf "no engine: %s" message)

let compile bytes =
  match Wasm_module.compile (Lazy.force engine) bytes with
  | Ok m -> m
  | Error (Not_compiled message) -> Alcotest.failf "not compiled: %s" message

let limits ~fuel ~memory ~table =
  match Instance.limits ~fuel ~memory ~table with
  | Ok limits -> limits
  | Error (Negative _) -> invalid_arg "Test_wasm_engine.limits"

let changed ?fuel ?memory ?table (base : Instance.limits) =
  limits
    ~fuel:(Option.value fuel ~default:base.fuel)
    ~memory:(Option.value memory ~default:base.memory)
    ~table:(Option.value table ~default:base.table)

let small = limits ~fuel:1_000_000 ~memory:(1 lsl 20) ~table:1_000
let generous = limits ~fuel:1_000_000_000 ~memory:(1 lsl 28) ~table:100_000

let with_instance ?(limits = generous) m action =
  match Instance.create m limits with
  | Ok instance ->
      Fun.protect
        ~finally:(fun () -> Instance.release instance)
        (fun () -> action instance)
  | Error _ -> Alcotest.fail "the instantiation failed"

let failure_text = function
  | Instance.Trap message -> "trap: " ^ message
  | Stack_exhausted -> "stack exhausted"
  | Stopped Fuel -> "stopped for fuel"
  | Stopped Memory -> "stopped for memory"
  | Stopped Table -> "stopped for table"
  | Busy -> "busy"
  | Fault message -> "fault: " ^ message

let ok what = function
  | Ok value -> value
  | Error failure -> Alcotest.failf "%s: %s" what (failure_text failure)

let size i name = ok "memory_size" (Instance.memory_size i name)

let read i ~address ~length =
  ok "read" (Instance.read i ~memory:"memory" ~address ~length)

let write i ~address bytes =
  ok "write" (Instance.write i ~memory:"memory" ~address bytes)

let invoke_i32 instance name arguments =
  match Instance.invoke instance name arguments Instance.Result_type.I32 with
  | Ok value -> value
  | Error failure -> Alcotest.failf "%s failed: %s" name (failure_text failure)

let raises_invalid_argument what action =
  match action () with
  | _ -> Alcotest.failf "%s: no Invalid_argument" what
  | exception Invalid_argument _ -> ()

let fails_with what expected = function
  | Error failure when failure = expected -> ()
  | Error failure ->
      Alcotest.failf "%s: %s, not %s" what (failure_text failure)
        (failure_text expected)
  | Ok _ -> Alcotest.failf "%s: no failure" what

let traps what = function
  | Error (Instance.Trap _) -> ()
  | Error failure ->
      Alcotest.failf "%s: %s, not a trap" what (failure_text failure)
  | Ok _ -> Alcotest.failf "%s: no failure" what

let case name action = Alcotest.test_case name `Quick action

let engine_cases =
  [
    case "an engine with a stack of 0 bytes is not made" (fun () ->
        match Engine.create ~stack:0 with
        | Error (Not_made _) -> ()
        | Ok _ -> Alcotest.fail "an engine with no stack");
    case "a negative stack or one past what the engine supports is not made"
      (fun () ->
        List.iter
          (fun stack ->
            match Engine.create ~stack with
            | Error (Not_made _) -> ()
            | Ok _ -> Alcotest.failf "an engine with the stack %d" stack)
          [ -1; min_int; 1 lsl 30; max_int ]);
    case "an engine with a stack of 1 byte is made" (fun () ->
        match Engine.create ~stack:1 with
        | Ok _ -> ()
        | Error (Not_made message) -> Alcotest.fail message);
    case "the code of an engine with a small stack exhausts it sooner"
      (fun () ->
        let deep =
          W.of_text
            "(module (func $f (export \"f\") (param $n i32) (result i32) (if \
             (result i32) (i32.eqz (local.get $n)) (then (i32.const 0)) (else \
             (i32.add (i32.const 1) (call $f (i32.sub (local.get $n) \
             (i32.const 1))))))))"
        in
        match Engine.create ~stack:65_536 with
        | Error (Not_made message) -> Alcotest.fail message
        | Ok small_engine -> (
            let run engine depth =
              match Wasm_module.compile engine deep with
              | Error _ -> Alcotest.fail "not compiled"
              | Ok m ->
                  with_instance m (fun i ->
                      Instance.invoke i "f" [ I32 (Int32.of_int depth) ] I32)
            in
            (match run small_engine 1_000_000 with
            | Error Stack_exhausted -> ()
            | other ->
                Alcotest.failf "a depth of 1,000,000 in 65,536 bytes: %s"
                  (match other with
                  | Ok v -> Int32.to_string v
                  | Error f -> failure_text f));
            match run (Lazy.force engine) 10 with
            | Ok 10l -> ()
            | _ -> Alcotest.fail "a depth of 10 gives 10"));
  ]

let not_compiled what bytes =
  match Wasm_module.compile (Lazy.force engine) bytes with
  | Error (Not_compiled _) -> ()
  | Ok _ -> Alcotest.failf "%s compiled" what

let module_cases =
  [
    case "each feature of Core 2.0 compiles" (fun () ->
        List.iter
          (fun (feature, bytes) ->
            match Wasm_module.compile (Lazy.force engine) bytes with
            | Ok _ -> ()
            | Error (Not_compiled message) ->
                Alcotest.failf "%s: %s" feature message)
          Adapter_fixtures.core_2_features);
    case "no construct of a later proposal compiles" (fun () ->
        List.iter
          (fun (proposal, bytes) -> not_compiled proposal bytes)
          Adapter_fixtures.later_proposals);
    case "a module with several memories does not compile" (fun () ->
        not_compiled "two memories"
          (W.adapter { W.base with memory = W.vec [ "\x00\x01"; "\x00\x01" ] }));
    case "a module in the text format does not compile" (fun () ->
        not_compiled "the text" "(module (func (export \"f\")))");
    case "a component does not compile" (fun () ->
        not_compiled "a component" "\x00asm\x0d\x00\x01\x00");
    case "a custom section changes no validity" (fun () ->
        let bytes =
          W.adapter
            {
              W.base with
              extra_sections =
                [
                  (0, W.name "name" ^ "\xff\xff\xff"); (0, W.name "x" ^ "junk");
                ];
            }
        in
        ignore (compile bytes));
    case "the imports of a module are counted" (fun () ->
        let m =
          compile
            (W.of_text
               "(module (import \"a\" \"f\" (func)) (import \"a\" \"m\" \
                (memory 1)) (import \"b\" \"t\" (table 1 funcref)) (import \
                \"b\" \"g\" (global i32)))")
        in
        Alcotest.(check int) "imports" 4 (Wasm_module.import_count m);
        Alcotest.(check int)
          "no import" 0
          (Wasm_module.import_count (compile (W.of_text "(module)"))));
    case "the exports of a module are its exports, in their order" (fun () ->
        let m =
          compile
            (W.of_text
               "(module (func (export \"z\") (param i32 i64 f32 f64 v128 \
                funcref externref) (result i64 i32) (i64.const 0) (i32.const \
                0)) (memory (export \"m\") 1) (table (export \"t\") 1 funcref) \
                (global (export \"g\") i32 (i32.const 0)) (func (export \
                \"a\")))")
        in
        let open Wasm_module in
        let expected =
          [
            ( "z",
              Function
                {
                  params =
                    Value_type.[ I32; I64; F32; F64; V128; Funcref; Externref ];
                  results = Value_type.[ I64; I32 ];
                } );
            ("m", Memory);
            ("t", Table);
            ("g", Global);
            ("a", Function { params = []; results = [] });
          ]
        in
        if exports m <> expected then
          Alcotest.fail "the exports differ from those of the module");
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:300 ~name:"compile never raises" ~print:W.hex
         (Gen.oneof
            [
              Gen.string;
              Gen.map (fun s -> "\x00asm\x01\x00\x00\x00" ^ s) Gen.string;
            ])
         (fun bytes ->
           match Wasm_module.compile (Lazy.force engine) bytes with
           | Ok _ | Error (Not_compiled _) -> true));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:400
         ~name:"compile agrees with the reference interpreter"
         ~print:(fun t -> t)
         Wasm_gen.module_text
         (fun text ->
           let bytes = W.of_text_unchecked text in
           let compiled =
             match Wasm_module.compile (Lazy.force engine) bytes with
             | Ok _ -> true
             | Error _ -> false
           in
           compiled = (W.reference bytes = W.Accepted)));
  ]

let counter =
  lazy
    (compile
       (W.of_text
          "(module (memory (export \"memory\") 1) (global $c (mut i32) \
           (i32.const 0)) (func (export \"next\") (result i32) (global.set $c \
           (i32.add (global.get $c) (i32.const 1))) (global.get $c)) (func \
           (export \"byte\") (param i32) (result i32) (i32.load8_u (local.get \
           0))) (func (export \"nothing\")) (func (export \"wide\") (param \
           i64) (result i64) (i64.add (local.get 0) (i64.const 1))))"))

let identity =
  lazy
    (compile
       (W.of_text
          "(module (func (export \"same32\") (param i32) (result i32) \
           (local.get 0)) (func (export \"same64\") (param i64) (result i64) \
           (local.get 0)) (func (export \"low\") (param i64) (result i32) \
           (i32.wrap_i64 (local.get 0))) (func (export \"widen\") (param i32) \
           (result i64) (i64.extend_i32_u (local.get 0))))"))

let grow_text ?(maximum = "") ~delta ~table () =
  W.of_text
    (Printf.sprintf
       "(module (memory (export \"memory\") 1 %s) (table 1 %s funcref) (func \
        (export \"grow\") (result i32) (%s (i32.const %s))) (func (export \
        \"after\") (result i32) (drop (%s (i32.const %s))) (i32.const 7)))"
       (if table then "" else maximum)
       (if table then maximum else "")
       (if table then "table.grow (ref.null func)" else "memory.grow")
       delta
       (if table then "table.grow (ref.null func)" else "memory.grow")
       delta)

let looping =
  lazy
    (compile
       (W.of_text
          "(module (memory 1) (func (export \"loop\") (loop $l (br $l))) (func \
           (export \"fill\") (memory.fill (i32.const 0) (i32.const 1) \
           (i32.const 65536))) (func $r (export \"recurse\") (call $r)))"))

let rec spin_when_free i =
  match Instance.invoke i "spin" [] Instance.Result_type.Nothing with
  | Error Busy ->
      Domain.cpu_relax ();
      spin_when_free i
  | result -> result

let rec wait_for_the_use i =
  match Instance.memory_size i "memory" with
  | Error Busy -> ()
  | Ok _ ->
      Domain.cpu_relax ();
      wait_for_the_use i
  | Error f -> Alcotest.fail (failure_text f)

let instance_cases =
  [
    case "an instantiation with an import raises Invalid_argument" (fun () ->
        let m = compile (W.of_text "(module (import \"a\" \"f\" (func)))") in
        raises_invalid_argument "an import" (fun () ->
            Instance.create m generous));
    case "a negative number gives no limits" (fun () ->
        let given =
          Alcotest.testable (fun f _ -> Format.pp_print_string f "limits") ( = )
        in
        let negative l = Error (Instance.Negative l) in
        List.iter
          (fun (what, (fuel, memory, table), expected) ->
            Alcotest.(check (result unit given))
              what expected
              (Result.map ignore (Instance.limits ~fuel ~memory ~table)))
          [
            ("fuel", (-1, -1, -1), negative Fuel);
            ("memory", (0, -1, -1), negative Memory);
            ("table", (0, 0, -1), negative Table);
            ("none", (0, 0, 0), Ok ());
            ("the least", (min_int, 5, 5), negative Fuel);
          ]);
    case "the limits keep their values, and limits of 0 are limits" (fun () ->
        let l = limits ~fuel:3 ~memory:5 ~table:7 in
        Alcotest.(check (list int))
          "the values" [ 3; 5; 7 ]
          [ l.fuel; l.memory; l.table ];
        let none = limits ~fuel:0 ~memory:0 ~table:0 in
        fails_with "an instantiation of a memory under the memory 0"
          (Instance.Stopped Memory)
          (Instance.create (compile (W.of_text "(module (memory 1))")) none);
        fails_with "an instantiation of a table under the table 0"
          (Instance.Stopped Table)
          (Instance.create
             (compile (W.of_text "(module (table 1 funcref))"))
             none);
        match Instance.create (compile (W.of_text "(module)")) none with
        | Ok i -> Instance.release i
        | Error f -> Alcotest.fail (failure_text f));
    case "the instantiation runs the start function" (fun () ->
        let m =
          compile
            (W.of_text
               "(module (global $g (mut i32) (i32.const 0)) (func $s \
                (global.set $g (i32.const 42))) (start $s) (func (export \
                \"g\") (result i32) (global.get $g)))")
        in
        with_instance m (fun i ->
            Alcotest.(check int32)
              "the start function ran" 42l (invoke_i32 i "g" [])));
    case "an instantiation whose start function traps fails" (fun () ->
        let m =
          compile (W.of_text "(module (func $s unreachable) (start $s))")
        in
        traps "the start function" (Instance.create m small));
    case "an instantiation whose data lie outside the memory fails" (fun () ->
        let m =
          compile
            (W.of_text "(module (memory 1) (data (i32.const 65535) \"ab\"))")
        in
        traps "the data" (Instance.create m small));
    case "two instances of one module share no global and no memory" (fun () ->
        let m = Lazy.force counter in
        with_instance m (fun a ->
            with_instance m (fun b ->
                write a ~address:5 "\x09";
                Alcotest.(check int32) "a" 1l (invoke_i32 a "next" []);
                Alcotest.(check int32) "a again" 2l (invoke_i32 a "next" []);
                Alcotest.(check int32) "b" 1l (invoke_i32 b "next" []);
                Alcotest.(check int32)
                  "a's byte" 9l
                  (invoke_i32 a "byte" [ I32 5l ]);
                Alcotest.(check int32)
                  "b's byte" 0l
                  (invoke_i32 b "byte" [ I32 5l ]))));
    case "invoke gives no result, an i32, or an i64" (fun () ->
        with_instance (Lazy.force counter) (fun i ->
            (match
               Instance.invoke i "nothing" [] Instance.Result_type.Nothing
             with
            | Ok () -> ()
            | Error f -> Alcotest.fail (failure_text f));
            match
              Instance.invoke i "wide" [ I64 41L ] Instance.Result_type.I64
            with
            | Ok 42L -> ()
            | _ -> Alcotest.fail "wide gives 42"));
    case "invoke raises Invalid_argument on a wrong name or type" (fun () ->
        with_instance (Lazy.force counter) (fun i ->
            raises_invalid_argument "no such export" (fun () ->
                Instance.invoke i "none" [] Instance.Result_type.I32);
            raises_invalid_argument "a memory as a function" (fun () ->
                Instance.invoke i "memory" [] Instance.Result_type.I32);
            raises_invalid_argument "a missing argument" (fun () ->
                Instance.invoke i "byte" [] Instance.Result_type.I32);
            raises_invalid_argument "an argument of the wrong type" (fun () ->
                Instance.invoke i "byte" [ I64 0L ] Instance.Result_type.I32);
            raises_invalid_argument "a result of the wrong type" (fun () ->
                Instance.invoke i "next" [] Instance.Result_type.I64);
            raises_invalid_argument "a result where none is" (fun () ->
                Instance.invoke i "nothing" [] Instance.Result_type.I32)));
    case "a released instance raises Invalid_argument and releases again"
      (fun () ->
        match Instance.create (Lazy.force counter) small with
        | Error _ -> Alcotest.fail "no instance"
        | Ok i ->
            Instance.release i;
            Instance.release i;
            raises_invalid_argument "invoke" (fun () ->
                Instance.invoke i "next" [] Instance.Result_type.I32);
            raises_invalid_argument "memory_size" (fun () ->
                Instance.memory_size i "memory");
            raises_invalid_argument "read" (fun () ->
                Instance.read i ~memory:"memory" ~address:0 ~length:1);
            raises_invalid_argument "write" (fun () ->
                Instance.write i ~memory:"memory" ~address:0 "a"));
    case "a trap fails the invocation, and the instance goes on" (fun () ->
        let m =
          compile
            (W.of_text
               "(module (func (export \"t\") (result i32) unreachable) (func \
                (export \"d\") (param i32) (result i32) (i32.div_u (i32.const \
                1) (local.get 0))))")
        in
        with_instance m (fun i ->
            traps "unreachable"
              (Instance.invoke i "t" [] Instance.Result_type.I32);
            traps "a division by 0"
              (Instance.invoke i "d" [ I32 0l ] Instance.Result_type.I32);
            Alcotest.(check int32) "1 / 1" 1l (invoke_i32 i "d" [ I32 1l ])));
    case "code that never ends stops for fuel" (fun () ->
        with_instance ~limits:small (Lazy.force looping) (fun i ->
            fails_with "a loop" (Instance.Stopped Fuel)
              (Instance.invoke i "loop" [] Instance.Result_type.Nothing)));
    case "the fuel of an instance is shared by its invocations" (fun () ->
        with_instance ~limits:(changed ~fuel:200_000 small) (Lazy.force looping)
          (fun i ->
            let rec go n =
              if n > 1_000 then Alcotest.fail "the fuel never ran out"
              else
                match
                  Instance.invoke i "fill" [] Instance.Result_type.Nothing
                with
                | Ok () -> go (n + 1)
                | Error (Stopped Fuel) -> ()
                | Error f -> Alcotest.fail (failure_text f)
            in
            go 0));
    case "a bulk instruction costs fuel for each byte" (fun () ->
        with_instance ~limits:(changed ~fuel:10_000 small) (Lazy.force looping)
          (fun i ->
            fails_with "a fill of 65,536 bytes with 10,000 units"
              (Instance.Stopped Fuel)
              (Instance.invoke i "fill" [] Instance.Result_type.Nothing)));
    case "recursion that never ends exhausts the call stack" (fun () ->
        with_instance (Lazy.force looping) (fun i ->
            fails_with "a recursion" Instance.Stack_exhausted
              (Instance.invoke i "recurse" [] Instance.Result_type.Nothing)));
    case "a growth past the maximum gives -1, and the code goes on" (fun () ->
        List.iter
          (fun (what, text) ->
            with_instance (compile text) (fun i ->
                Alcotest.(check int32) what (-1l) (invoke_i32 i "grow" []);
                Alcotest.(check int32)
                  (what ^ ", then") 7l (invoke_i32 i "after" [])))
          [
            ( "a memory of at most 2 pages",
              grow_text ~maximum:"2" ~delta:"5" ~table:false () );
            ( "a memory with no maximum",
              grow_text ~delta:"65536" ~table:false () );
            ( "a memory by 2^32 - 1 pages",
              grow_text ~maximum:"3" ~delta:"-1" ~table:false () );
            ( "a table of at most 2 elements",
              grow_text ~maximum:"2" ~delta:"5" ~table:true () );
            ("a table with no maximum", grow_text ~delta:"-1" ~table:true ());
          ]);
    case "a growth within the maximum past a limit stops the code" (fun () ->
        with_instance
          ~limits:(changed ~memory:(65_536 * 2) small)
          (compile (grow_text ~delta:"5" ~table:false ()))
          (fun i ->
            fails_with "memory" (Instance.Stopped Memory)
              (Instance.invoke i "grow" [] Instance.Result_type.I32));
        with_instance ~limits:(changed ~table:3 small)
          (compile (grow_text ~delta:"5" ~table:true ()))
          (fun i ->
            fails_with "table" (Instance.Stopped Table)
              (Instance.invoke i "grow" [] Instance.Result_type.I32)));
    case "an instantiation past a limit stops" (fun () ->
        fails_with "a memory of 4 pages" (Instance.Stopped Memory)
          (Instance.create
             (compile (W.of_text "(module (memory 4))"))
             (changed ~memory:(65_536 * 2) small));
        fails_with "a table of 10 elements" (Instance.Stopped Table)
          (Instance.create
             (compile (W.of_text "(module (table 10 funcref))"))
             (changed ~table:3 small)));
    case "the size of a memory follows its growth" (fun () ->
        with_instance
          (compile (grow_text ~maximum:"4" ~delta:"1" ~table:false ()))
          (fun i ->
            Alcotest.(check int) "1 page" 65_536 (size i "memory");
            Alcotest.(check int32) "the old size" 1l (invoke_i32 i "grow" []);
            Alcotest.(check int) "2 pages" 131_072 (size i "memory")));
    case "read and write keep to the bounds of the memory" (fun () ->
        with_instance (Lazy.force counter) (fun i ->
            write i ~address:65_533 "xyz";
            Alcotest.(check string)
              "the last bytes" "xyz"
              (read i ~address:65_533 ~length:3);
            Alcotest.(check string)
              "no byte at the end" ""
              (read i ~address:65_536 ~length:0);
            write i ~address:65_536 "";
            List.iter
              (fun (what, action) -> raises_invalid_argument what action)
              [
                ( "read past the end",
                  fun () ->
                    ignore
                      (Instance.read i ~memory:"memory" ~address:65_534
                         ~length:3) );
                ( "read at a negative address",
                  fun () ->
                    ignore
                      (Instance.read i ~memory:"memory" ~address:(-1) ~length:1)
                );
                ( "read a negative length",
                  fun () ->
                    ignore
                      (Instance.read i ~memory:"memory" ~address:0 ~length:(-1))
                );
                ( "read another memory",
                  fun () ->
                    ignore (Instance.read i ~memory:"next" ~address:0 ~length:1)
                );
                ( "write past the end",
                  fun () ->
                    ignore
                      (Instance.write i ~memory:"memory" ~address:65_535 "ab")
                );
                ( "write at a negative address",
                  fun () ->
                    ignore (Instance.write i ~memory:"memory" ~address:(-1) "a")
                );
                ( "write another memory",
                  fun () ->
                    ignore (Instance.write i ~memory:"none" ~address:0 "a") );
                ( "the size of another memory",
                  fun () -> ignore (Instance.memory_size i "next") );
              ]));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:200
         ~name:"a write changes only its own bytes, and a read gives them"
         Gen.(pair (int_bound 65_536) (string_size ~gen:char (int_bound 300)))
         (fun (address, bytes) ->
           let address = min address (65_536 - String.length bytes) in
           with_instance (Lazy.force counter) (fun i ->
               let before =
                 String.init 65_536 (fun k -> Char.chr (k * 7 land 255))
               in
               write i ~address:0 before;
               write i ~address bytes;
               let after = read i ~address:0 ~length:65_536 in
               let expected =
                 String.sub before 0 address
                 ^ bytes
                 ^ String.sub before
                     (address + String.length bytes)
                     (65_536 - address - String.length bytes)
               in
               after = expected
               && read i ~address ~length:(String.length bytes) = bytes)));
    QCheck_alcotest.to_alcotest ~speed_level:`Quick
      (QCheck2.Test.make ~count:300
         ~name:"a value crosses an invocation as its bits"
         Gen.(
           pair
             (oneof
                [
                  int32;
                  oneof_list [ 0l; -1l; 1l; Int32.min_int; Int32.max_int ];
                ])
             (oneof
                [
                  int64;
                  oneof_list [ 0L; -1L; 1L; Int64.min_int; Int64.max_int ];
                ]))
         (fun (a, b) ->
           with_instance (Lazy.force identity) (fun i ->
               Instance.invoke i "same32" [ I32 a ] Instance.Result_type.I32
               = Ok a
               && Instance.invoke i "same64" [ I64 b ] Instance.Result_type.I64
                  = Ok b
               && Instance.invoke i "low" [ I64 b ] Instance.Result_type.I32
                  = Ok (Int64.to_int32 b)
               && Instance.invoke i "widen" [ I32 a ] Instance.Result_type.I64
                  = Ok (Int64.logand (Int64.of_int32 a) 0xFFFF_FFFFL))));
    case "a recursion without end exhausts the stack on any thread" (fun () ->
        let run stack =
          match Engine.create ~stack with
          | Error (Not_made message) -> Alcotest.fail message
          | Ok engine -> (
              match
                Wasm_module.compile engine
                  (W.of_text
                     "(module (func $r (export \"r\") (param i32) (result i32) \
                      (i32.add (local.get 0) (call $r (local.get 0)))))")
              with
              | Error _ -> Alcotest.fail "not compiled"
              | Ok m ->
                  with_instance m (fun i ->
                      fails_with
                        (Printf.sprintf "a stack of %d bytes" stack)
                        Instance.Stack_exhausted
                        (Instance.invoke i "r" [ I32 1l ]
                           Instance.Result_type.I32)))
        in
        let stacks = [ 65_536; 524_288; 2_097_152 ] in
        List.iter run stacks;
        Domain.join (Domain.spawn (fun () -> List.iter run stacks)));
    case "a second domain that uses an instance in use is busy" (fun () ->
        let m =
          compile
            (W.of_text
               "(module (memory (export \"memory\") 1) (func (export \"spin\") \
                (loop $l (br $l))) (func (export \"one\") (result i32) \
                (i32.const 1)))")
        in
        with_instance ~limits:(changed ~fuel:300_000_000 small) m (fun i ->
            let finished = Atomic.make false in
            let spinner =
              Domain.spawn (fun () ->
                  let result = spin_when_free i in
                  Atomic.set finished true;
                  result)
            in
            wait_for_the_use i;
            let busy = ref 0 in
            while not (Atomic.get finished) do
              (match Instance.write i ~memory:"memory" ~address:9 "\x01" with
              | Error Busy -> incr busy
              | Ok () -> (
                  match Instance.write i ~memory:"memory" ~address:9 "\x00" with
                  | Ok () -> ()
                  | Error f -> Alcotest.fail (failure_text f))
              | Error f -> Alcotest.fail (failure_text f));
              (match Instance.invoke i "one" [] Instance.Result_type.I32 with
              | Error Busy -> incr busy
              | Error (Stopped Fuel) -> ()
              | Ok 1l -> ()
              | Ok _ -> Alcotest.fail "one is not 1"
              | Error f -> Alcotest.fail (failure_text f));
              match Instance.memory_size i "memory" with
              | Error Busy | Ok 65_536 -> ()
              | Ok n -> Alcotest.failf "a size of %d" n
              | Error f -> Alcotest.fail (failure_text f)
            done;
            (match Domain.join spinner with
            | Error (Stopped Fuel) -> ()
            | Error f -> Alcotest.failf "the spin: %s" (failure_text f)
            | Ok () -> Alcotest.fail "the spin ended");
            if !busy = 0 then Alcotest.fail "no use was busy while the spin ran";
            Alcotest.(check string)
              "the byte that no busy write changed" "\x00"
              (read i ~address:9 ~length:1)));
    case "a release while another domain uses the instance waits for that use"
      (fun () ->
        let m =
          compile
            (W.of_text
               "(module (memory (export \"memory\") 1) (func (export \"spin\") \
                (loop $l (br $l))))")
        in
        match Instance.create m (changed ~fuel:300_000_000 small) with
        | Error f -> Alcotest.fail (failure_text f)
        | Ok i ->
            let spinner = Domain.spawn (fun () -> spin_when_free i) in
            wait_for_the_use i;
            Instance.release i;
            (match Domain.join spinner with
            | Error (Stopped Fuel) -> ()
            | Error f -> Alcotest.failf "the spin: %s" (failure_text f)
            | Ok () -> Alcotest.fail "the spin ended");
            raises_invalid_argument "an invocation after the release" (fun () ->
                Instance.invoke i "spin" [] Instance.Result_type.Nothing));
    case "two domains use one engine and one module at the same time" (fun () ->
        let m = Lazy.force counter in
        let work () =
          List.init 50 (fun _ ->
              with_instance m (fun i ->
                  ignore (invoke_i32 i "next" []);
                  invoke_i32 i "next" []))
        in
        let other = Domain.spawn work in
        let mine = work () in
        let theirs = Domain.join other in
        if List.exists (( <> ) 2l) (mine @ theirs) then
          Alcotest.fail "an instance saw another's global");
  ]

let tests = engine_cases @ module_cases @ instance_cases
