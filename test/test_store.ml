(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

open Sinter_wasm_engine
module W = Wasm_modules

let engine =
  lazy
    (match Engine.create ~stack:524_288 with
    | Ok engine -> engine
    | Error (Not_made message) -> Alcotest.failf "no engine: %s" message)

let compile bytes =
  match Wasm_module.compile (Lazy.force engine) bytes with
  | Ok m -> m
  | Error (Not_compiled message) -> Alcotest.failf "not compiled: %s" message

let module_of text = compile (W.of_text text)

let limits ~fuel ~memory ~table =
  match Instance.limits ~fuel ~memory ~table with
  | Ok limits -> limits
  | Error (Negative _) -> invalid_arg "Test_store.limits"

let page = 65_536
let generous = limits ~fuel:1_000_000_000 ~memory:(1 lsl 28) ~table:100_000

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

let with_store ?(limits = generous) action =
  let store = Store.create (Lazy.force engine) limits in
  Fun.protect ~finally:(fun () -> Store.release store) (fun () -> action store)

let instantiate store m imports =
  ok "the instantiation" (Store.instantiate store m imports)

let invoke_i32 store i name arguments =
  ok name (Store.invoke store i name arguments Instance.Result_type.I32)

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

let faults what = function
  | Error (Instance.Fault _) -> ()
  | Error failure ->
      Alcotest.failf "%s: %s, not a fault" what (failure_text failure)
  | Ok _ -> Alcotest.failf "%s: no failure" what

let raises_invalid_argument what action =
  match action () with
  | _ -> Alcotest.failf "%s: no Invalid_argument" what
  | exception Invalid_argument _ -> ()

let case name action = Alcotest.test_case name `Quick action

let provider =
  lazy
    (module_of
       "(module (memory (export \"memory\") 1) (table (export \"table\") 2 \
        funcref) (global (export \"g\") (mut i32) (i32.const 7)) (func (export \
        \"load\") (param i32) (result i32) (i32.load8_u (local.get 0))) (func \
        (export \"get\") (result i32) (global.get 0)) (func (export \"size\") \
        (result i32) (table.size 0)) (func (export \"pages\") (result i32) \
        (memory.size)))")

let consumer =
  lazy
    (module_of
       "(module (import \"x\" \"memory\" (memory 1)) (import \"x\" \"table\" \
        (table 1 funcref)) (import \"x\" \"g\" (global (mut i32))) (import \
        \"x\" \"f\" (func $f (result i32))) (func (export \"store\") (param \
        i32 i32) (i32.store8 (local.get 0) (local.get 1))) (func (export \
        \"set\") (param i32) (global.set 0 (local.get 0))) (func (export \
        \"grow\") (param i32) (result i32) (table.grow 0 (ref.null func) \
        (local.get 0))) (func (export \"call\") (result i32) (call $f)))")

let importer_of_global ~mutable_ =
  module_of
    (Printf.sprintf
       "(module (import \"env\" \"g\" (global %s)) (func (export \"get\") \
        (result i32) (global.get 0)))"
       (if mutable_ then "(mut i32)" else "i32"))

let spinner =
  lazy
    (module_of
       "(module (memory (export \"memory\") 1) (func (export \"spin\") (loop \
        $l (br $l))) (func (export \"one\") (result i32) (i32.const 1)))")

let link_cases =
  [
    case "an instance reads what another instance of the store writes"
      (fun () ->
        with_store (fun store ->
            let a = instantiate store (Lazy.force provider) [] in
            let f =
              module_of
                "(module (func (export \"f\") (result i32) (i32.const 3)))"
            in
            let fi = instantiate store f [] in
            let b =
              instantiate store (Lazy.force consumer)
                [
                  Store.Export (a, "memory");
                  Export (a, "table");
                  Export (a, "g");
                  Export (fi, "f");
                ]
            in
            ignore
              (ok "store"
                 (Store.invoke store b "store" [ I32 5l; I32 9l ] Nothing));
            ignore (ok "set" (Store.invoke store b "set" [ I32 11l ] Nothing));
            Alcotest.(check int32)
              "the byte" 9l
              (invoke_i32 store a "load" [ I32 5l ]);
            Alcotest.(check int32)
              "the global" 11l
              (invoke_i32 store a "get" []);
            Alcotest.(check int32)
              "the old table size" 2l
              (invoke_i32 store b "grow" [ I32 3l ]);
            Alcotest.(check int32)
              "the table size" 5l
              (invoke_i32 store a "size" []);
            Alcotest.(check int32)
              "the function" 3l
              (invoke_i32 store b "call" [])));
    case "a global import gives a new global with its value" (fun () ->
        with_store (fun store ->
            List.iter
              (fun mutable_ ->
                let i =
                  instantiate store
                    (importer_of_global ~mutable_)
                    [ Store.Global { mutable_; value = -5l } ]
                in
                Alcotest.(check int32)
                  "the value" (-5l)
                  (invoke_i32 store i "get" []))
              [ false; true ]));
    case "a global import of another mutability is a fault" (fun () ->
        with_store (fun store ->
            List.iter
              (fun mutable_ ->
                faults "the instantiation"
                  (Store.instantiate store
                     (importer_of_global ~mutable_)
                     [ Store.Global { mutable_ = not mutable_; value = 0l } ]))
              [ false; true ]));
    case "an export of another kind or type for an import is a fault" (fun () ->
        with_store (fun store ->
            let a = instantiate store (Lazy.force provider) [] in
            faults "a memory for a global"
              (Store.instantiate store
                 (importer_of_global ~mutable_:true)
                 [ Store.Export (a, "memory") ]);
            faults "a function of another type"
              (Store.instantiate store (Lazy.force consumer)
                 [
                   Store.Export (a, "memory");
                   Export (a, "table");
                   Export (a, "g");
                   Export (a, "load");
                 ])));
    case "a function import of Trap traps each time it is invoked" (fun () ->
        with_store (fun store ->
            let m =
              module_of
                "(module (import \"env\" \"f\" (func $f (param i32) (result \
                 i32))) (func (export \"call\") (result i32) (call $f \
                 (i32.const 1))))"
            in
            let i = instantiate store m [ Store.Trap ] in
            traps "the first call" (Store.invoke store i "call" [] I32);
            traps "the second call" (Store.invoke store i "call" [] I32)));
    case "an instantiation runs the start function" (fun () ->
        with_store (fun store ->
            let m =
              module_of
                "(module (global (mut i32) (i32.const 0)) (func $s (global.set \
                 0 (i32.const 4))) (start $s) (func (export \"get\") (result \
                 i32) (global.get 0)))"
            in
            let i = instantiate store m [] in
            Alcotest.(check int32) "the global" 4l (invoke_i32 store i "get" []);
            let t = module_of "(module (func $s unreachable) (start $s))" in
            traps "a start function that traps" (Store.instantiate store t [])));
    case "the stores of one module share no memory and no global" (fun () ->
        with_store (fun s1 ->
            with_store (fun s2 ->
                let m = Lazy.force provider in
                let a = instantiate s1 m [] and b = instantiate s2 m [] in
                ok "write" (Store.write s1 a ~memory:"memory" ~address:3 "\x2a");
                Alcotest.(check string)
                  "the byte of the other store" "\x00"
                  (ok "read"
                     (Store.read s2 b ~memory:"memory" ~address:3 ~length:1));
                let c =
                  instantiate s2 (Lazy.force consumer)
                    [
                      Store.Export (b, "memory");
                      Export (b, "table");
                      Export (b, "g");
                      Export
                        ( instantiate s2
                            (module_of
                               "(module (func (export \"f\") (result i32) \
                                (i32.const 0)))")
                            [],
                          "f" );
                    ]
                in
                ignore (ok "set" (Store.invoke s2 c "set" [ I32 99l ] Nothing));
                Alcotest.(check int32)
                  "the global of the first store" 7l (invoke_i32 s1 a "get" []))));
    case "a wrong count of imports raises Invalid_argument" (fun () ->
        with_store (fun store ->
            raises_invalid_argument "no import for one" (fun () ->
                Store.instantiate store (importer_of_global ~mutable_:false) []);
            raises_invalid_argument "two imports for one" (fun () ->
                Store.instantiate store
                  (importer_of_global ~mutable_:false)
                  [ Store.Trap; Store.Trap ])));
    case
      "an export of another store or a name not exported raises \
       Invalid_argument" (fun () ->
        with_store (fun s1 ->
            with_store (fun s2 ->
                let a = instantiate s1 (Lazy.force provider) [] in
                raises_invalid_argument "another store" (fun () ->
                    Store.instantiate s2
                      (importer_of_global ~mutable_:true)
                      [ Store.Export (a, "g") ]);
                raises_invalid_argument "a name not exported" (fun () ->
                    Store.instantiate s1
                      (importer_of_global ~mutable_:true)
                      [ Store.Export (a, "nothing") ]))));
    case
      "an instance of another store raises Invalid_argument, even when that \
       store has an instance at the same place" (fun () ->
        with_store (fun s1 ->
            with_store (fun s2 ->
                let m = Lazy.force provider in
                let a = instantiate s1 m [] in
                ignore (instantiate s2 m []);
                raises_invalid_argument "memory_size" (fun () ->
                    Store.memory_size s2 a "memory");
                raises_invalid_argument "read" (fun () ->
                    Store.read s2 a ~memory:"memory" ~address:0 ~length:1);
                raises_invalid_argument "write" (fun () ->
                    Store.write s2 a ~memory:"memory" ~address:0 "x");
                raises_invalid_argument "grow_memory" (fun () ->
                    Store.grow_memory s2 a "memory" 0);
                raises_invalid_argument "grow_table" (fun () ->
                    Store.grow_table s2 a "table" 0))));
    case "a module of another engine raises Invalid_argument" (fun () ->
        match Engine.create ~stack:524_288 with
        | Error (Not_made m) -> Alcotest.fail m
        | Ok other -> (
            match Wasm_module.compile other (W.of_text "(module)") with
            | Error _ -> Alcotest.fail "not compiled"
            | Ok m ->
                with_store (fun store ->
                    raises_invalid_argument "another engine" (fun () ->
                        Store.instantiate store m []))));
  ]

let limit_cases =
  [
    case "the fuel of a store is for all of its instances together" (fun () ->
        with_store
          ~limits:(limits ~fuel:100_000 ~memory:(1 lsl 24) ~table:100)
          (fun store ->
            let a = instantiate store (Lazy.force spinner) [] in
            let b = instantiate store (Lazy.force spinner) [] in
            fails_with "the spin" (Instance.Stopped Fuel)
              (Store.invoke store a "spin" [] Nothing);
            fails_with "a call in the other instance" (Instance.Stopped Fuel)
              (Store.invoke store b "one" [] I32)));
    case "the memory of a store is for all of its instances together" (fun () ->
        with_store
          ~limits:(limits ~fuel:1_000_000 ~memory:(3 * page) ~table:100)
          (fun store ->
            let two = module_of "(module (memory 2))" in
            ignore (instantiate store two []);
            fails_with "the second instance" (Instance.Stopped Memory)
              (Store.instantiate store two [])));
    case "the table elements of a store are for all of its instances together"
      (fun () ->
        with_store ~limits:(limits ~fuel:1_000_000 ~memory:page ~table:30)
          (fun store ->
            let twenty = module_of "(module (table 20 funcref))" in
            ignore (instantiate store twenty []);
            fails_with "the second instance" (Instance.Stopped Table)
              (Store.instantiate store twenty [])));
    case "memory.grow stops, and never gives -1, past a limit or a maximum"
      (fun () ->
        List.iter
          (fun (memory_type, pages) ->
            with_store
              ~limits:(limits ~fuel:1_000_000 ~memory:(4 * page) ~table:100)
              (fun store ->
                let m =
                  module_of
                    (Printf.sprintf
                       "(module (memory %s) (func (export \"grow\") (param \
                        i32) (result i32) (memory.grow (local.get 0))))"
                       memory_type)
                in
                let i = instantiate store m [] in
                fails_with
                  (Printf.sprintf "memory %s, grow %d" memory_type pages)
                  (Instance.Stopped Memory)
                  (Store.invoke store i "grow" [ I32 (Int32.of_int pages) ] I32)))
          [ ("1", 4); ("1 2", 2); ("1 1", 1) ]);
    case "memory.grow past 65,536 pages stops" (fun () ->
        with_store ~limits:(limits ~fuel:1_000_000 ~memory:max_int ~table:100)
          (fun store ->
            let m =
              module_of
                "(module (memory 1) (func (export \"grow\") (param i32) \
                 (result i32) (memory.grow (local.get 0))))"
            in
            let i = instantiate store m [] in
            fails_with "a growth to 65,537 pages" (Instance.Stopped Memory)
              (Store.invoke store i "grow" [ I32 65_536l ] I32)));
    case "table.grow stops, and never gives -1, past a limit or a maximum"
      (fun () ->
        List.iter
          (fun (table_type, elements) ->
            with_store ~limits:(limits ~fuel:1_000_000 ~memory:page ~table:10)
              (fun store ->
                let m =
                  module_of
                    (Printf.sprintf
                       "(module (table %s funcref) (func (export \"grow\") \
                        (param i32) (result i32) (table.grow 0 (ref.null func) \
                        (local.get 0))))"
                       table_type)
                in
                let i = instantiate store m [] in
                fails_with
                  (Printf.sprintf "table %s, grow %d" table_type elements)
                  (Instance.Stopped Table)
                  (Store.invoke store i "grow"
                     [ I32 (Int32.of_int elements) ]
                     I32)))
          [ ("1", 10); ("1 3", 3) ]);
    case "a growth within the limits gives the old size" (fun () ->
        with_store (fun store ->
            let m =
              module_of
                "(module (memory 1) (table 1 funcref) (func (export \"grow\") \
                 (result i32) (memory.grow (i32.const 2))) (func (export \
                 \"tgrow\") (result i32) (table.grow 0 (ref.null func) \
                 (i32.const 3))))"
            in
            let i = instantiate store m [] in
            Alcotest.(check int32) "memory" 1l (invoke_i32 store i "grow" []);
            Alcotest.(check int32) "table" 1l (invoke_i32 store i "tgrow" [])));
  ]

let growth_cases =
  [
    case "grow_memory adds pages of zero bytes and gives the old size"
      (fun () ->
        with_store (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            Alcotest.(check int)
              "the old pages" 1
              (ok "grow" (Store.grow_memory store i "memory" 2));
            Alcotest.(check int)
              "the size" (3 * page)
              (ok "size" (Store.memory_size store i "memory"));
            Alcotest.(check int32)
              "the pages that the code sees" 3l
              (invoke_i32 store i "pages" []);
            Alcotest.(check string)
              "the new bytes" (String.make 16 '\x00')
              (ok "read"
                 (Store.read store i ~memory:"memory"
                    ~address:((3 * page) - 16)
                    ~length:16))));
    case "grow_memory past the limit stops and changes nothing" (fun () ->
        with_store
          ~limits:(limits ~fuel:1_000_000 ~memory:(2 * page) ~table:100)
          (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            fails_with "the growth" (Instance.Stopped Memory)
              (Store.grow_memory store i "memory" 2);
            Alcotest.(check int)
              "the size" page
              (ok "size" (Store.memory_size store i "memory"))));
    case "grow_memory past 65,536 pages stops" (fun () ->
        with_store ~limits:(limits ~fuel:1_000_000 ~memory:max_int ~table:100)
          (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            fails_with "the growth" (Instance.Stopped Memory)
              (Store.grow_memory store i "memory" 65_536)));
    case "grow_table adds null elements and gives the old size" (fun () ->
        with_store (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            Alcotest.(check int)
              "the old size" 2
              (ok "grow" (Store.grow_table store i "table" 5));
            Alcotest.(check int32) "the size" 7l (invoke_i32 store i "size" [])));
    case "grow_table past the limit stops and changes nothing" (fun () ->
        with_store ~limits:(limits ~fuel:1_000_000 ~memory:page ~table:4)
          (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            fails_with "the growth" (Instance.Stopped Table)
              (Store.grow_table store i "table" 3);
            Alcotest.(check int32) "the size" 2l (invoke_i32 store i "size" [])));
    case "a growth of a negative size raises Invalid_argument" (fun () ->
        with_store (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            raises_invalid_argument "memory" (fun () ->
                Store.grow_memory store i "memory" (-1));
            raises_invalid_argument "table" (fun () ->
                Store.grow_table store i "table" (-1))));
    case "a growth of an export that is not of its kind raises Invalid_argument"
      (fun () ->
        with_store (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            let e =
              instantiate store
                (module_of "(module (table (export \"t\") 1 externref))")
                []
            in
            raises_invalid_argument "no memory of the name" (fun () ->
                Store.grow_memory store i "table" 1);
            raises_invalid_argument "no table of the name" (fun () ->
                Store.grow_table store i "memory" 1);
            raises_invalid_argument "a table of no functions" (fun () ->
                Store.grow_table store e "t" 1)));
  ]

let memory_cases =
  [
    case "write puts bytes that read gives back" (fun () ->
        with_store (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            ok "write" (Store.write store i ~memory:"memory" ~address:10 "abc");
            Alcotest.(check string)
              "the bytes" "\x00abc\x00"
              (ok "read"
                 (Store.read store i ~memory:"memory" ~address:9 ~length:5));
            Alcotest.(check int32)
              "the byte that the code reads" 98l
              (invoke_i32 store i "load" [ I32 11l ])));
    case "read and write at the end of the memory, and not past it" (fun () ->
        with_store (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            ok "write"
              (Store.write store i ~memory:"memory" ~address:(page - 1) "z");
            Alcotest.(check string)
              "the last byte" "z"
              (ok "read"
                 (Store.read store i ~memory:"memory" ~address:(page - 1)
                    ~length:1));
            Alcotest.(check string)
              "no byte" ""
              (ok "read"
                 (Store.read store i ~memory:"memory" ~address:page ~length:0));
            raises_invalid_argument "a read past the end" (fun () ->
                Store.read store i ~memory:"memory" ~address:(page - 1)
                  ~length:2);
            raises_invalid_argument "a write past the end" (fun () ->
                Store.write store i ~memory:"memory" ~address:(page - 1) "ab");
            raises_invalid_argument "a negative address" (fun () ->
                Store.read store i ~memory:"memory" ~address:(-1) ~length:1);
            raises_invalid_argument "a negative length" (fun () ->
                Store.read store i ~memory:"memory" ~address:0 ~length:(-1));
            raises_invalid_argument "a write at a negative address" (fun () ->
                Store.write store i ~memory:"memory" ~address:(-1) "a");
            raises_invalid_argument "no memory of the name" (fun () ->
                Store.read store i ~memory:"g" ~address:0 ~length:1);
            raises_invalid_argument "the size of no memory" (fun () ->
                Store.memory_size store i "table")));
    case
      "an invocation of a name, arguments, or result that do not fit raises \
       Invalid_argument" (fun () ->
        with_store (fun store ->
            let i = instantiate store (Lazy.force provider) [] in
            raises_invalid_argument "no such function" (fun () ->
                Store.invoke store i "nothing" [] I32);
            raises_invalid_argument "a memory as a function" (fun () ->
                Store.invoke store i "memory" [] I32);
            raises_invalid_argument "a missing argument" (fun () ->
                Store.invoke store i "load" [] I32);
            raises_invalid_argument "an argument of another type" (fun () ->
                Store.invoke store i "load" [ I64 1L ] I32);
            raises_invalid_argument "another result type" (fun () ->
                Store.invoke store i "load" [ I32 1l ] Nothing)));
    case "an instance of another store raises Invalid_argument" (fun () ->
        with_store (fun s1 ->
            with_store (fun s2 ->
                let a = instantiate s1 (Lazy.force provider) [] in
                raises_invalid_argument "invoke" (fun () ->
                    Store.invoke s2 a "get" [] I32);
                raises_invalid_argument "read" (fun () ->
                    Store.read s2 a ~memory:"memory" ~address:0 ~length:1);
                raises_invalid_argument "write" (fun () ->
                    Store.write s2 a ~memory:"memory" ~address:0 "a");
                raises_invalid_argument "memory_size" (fun () ->
                    Store.memory_size s2 a "memory");
                raises_invalid_argument "grow_memory" (fun () ->
                    Store.grow_memory s2 a "memory" 1);
                raises_invalid_argument "grow_table" (fun () ->
                    Store.grow_table s2 a "table" 1))));
  ]

let rec spin_when_free store i =
  match Store.invoke store i "spin" [] Instance.Result_type.Nothing with
  | Error Busy ->
      Domain.cpu_relax ();
      spin_when_free store i
  | result -> result

let rec wait_for_the_use store i =
  match Store.memory_size store i "memory" with
  | Error Busy -> ()
  | Ok _ ->
      Domain.cpu_relax ();
      wait_for_the_use store i
  | Error f -> Alcotest.fail (failure_text f)

let release_cases =
  [
    case
      "a release of a released store does nothing, and each use raises \
       Invalid_argument" (fun () ->
        let store = Store.create (Lazy.force engine) generous in
        let i = instantiate store (Lazy.force provider) [] in
        Store.release store;
        Store.release store;
        raises_invalid_argument "instantiate" (fun () ->
            Store.instantiate store (Lazy.force provider) []);
        raises_invalid_argument "invoke" (fun () ->
            Store.invoke store i "get" [] I32);
        raises_invalid_argument "read" (fun () ->
            Store.read store i ~memory:"memory" ~address:0 ~length:1);
        raises_invalid_argument "write" (fun () ->
            Store.write store i ~memory:"memory" ~address:0 "a");
        raises_invalid_argument "memory_size" (fun () ->
            Store.memory_size store i "memory");
        raises_invalid_argument "grow_memory" (fun () ->
            Store.grow_memory store i "memory" 1);
        raises_invalid_argument "grow_table" (fun () ->
            Store.grow_table store i "table" 1));
    case "a use while another domain uses the store is busy and changes nothing"
      (fun () ->
        with_store ~limits:(limits ~fuel:300_000_000 ~memory:page ~table:10)
          (fun store ->
            let i = instantiate store (Lazy.force spinner) [] in
            let finished = Atomic.make false in
            let other =
              Domain.spawn (fun () ->
                  let result = spin_when_free store i in
                  Atomic.set finished true;
                  result)
            in
            wait_for_the_use store i;
            let busy = ref 0 in
            while not (Atomic.get finished) do
              match Store.write store i ~memory:"memory" ~address:9 "\x01" with
              | Error Busy -> incr busy
              | Ok () -> (
                  match
                    Store.write store i ~memory:"memory" ~address:9 "\x00"
                  with
                  | Ok () -> ()
                  | Error f -> Alcotest.fail (failure_text f))
              | Error f -> Alcotest.fail (failure_text f)
            done;
            (match Domain.join other with
            | Error (Stopped Fuel) -> ()
            | Error f -> Alcotest.failf "the spin: %s" (failure_text f)
            | Ok () -> Alcotest.fail "the spin ended");
            if !busy = 0 then Alcotest.fail "no use was busy while the spin ran";
            Alcotest.(check string)
              "the byte that no busy write changed" "\x00"
              (ok "read"
                 (Store.read store i ~memory:"memory" ~address:9 ~length:1))));
    case "a release while another domain uses the store waits for that use"
      (fun () ->
        let store =
          Store.create (Lazy.force engine)
            (limits ~fuel:300_000_000 ~memory:page ~table:10)
        in
        let i = instantiate store (Lazy.force spinner) [] in
        let other = Domain.spawn (fun () -> spin_when_free store i) in
        wait_for_the_use store i;
        Store.release store;
        (match Domain.join other with
        | Error (Stopped Fuel) -> ()
        | Error f -> Alcotest.failf "the spin: %s" (failure_text f)
        | Ok () -> Alcotest.fail "the spin ended");
        raises_invalid_argument "an invocation after the release" (fun () ->
            Store.invoke store i "spin" [] Nothing));
  ]

let import_text (i : Wasm_module.import) =
  let types ts =
    String.concat " "
      (List.map
         (function
           | Wasm_module.Value_type.I32 -> "i32"
           | I64 -> "i64"
           | F32 -> "f32"
           | F64 -> "f64"
           | V128 -> "v128"
           | Funcref -> "funcref"
           | Externref -> "externref")
         ts)
  in
  let limits minimum maximum =
    Printf.sprintf "%d %s" minimum
      (match maximum with Some m -> string_of_int m | None -> "-")
  in
  Printf.sprintf "%s.%s %s" i.module_name i.name
    (match i.type_ with
    | Function_import { params; results } ->
        Printf.sprintf "func (%s) (%s)" (types params) (types results)
    | Memory_import { minimum; maximum } -> "memory " ^ limits minimum maximum
    | Table_import { element; minimum; maximum } ->
        Printf.sprintf "table %s %s" (types [ element ])
          (limits minimum maximum)
    | Global_import { value_type; mutable_ } ->
        Printf.sprintf "global %s%s"
          (if mutable_ then "mut " else "")
          (types [ value_type ]))

let module_cases =
  [
    case "imports gives each import with its type, in order" (fun () ->
        let m =
          module_of
            "(module (import \"a\" \"f\" (func (param i32 f64) (result i64))) \
             (import \"b\" \"m\" (memory 2 5)) (import \"\" \"t\" (table 3 \
             funcref)) (import \"c\" \"g\" (global (mut f32))) (import \"c\" \
             \"h\" (global externref)) (import \"d\" \"e\" (func)) (import \
             \"d\" \"u\" (table 0 9 externref)) (import \"x\" \"v\" (func \
             (param v128) (result funcref))))"
        in
        Alcotest.(check (list string))
          "imports"
          [
            "a.f func (i32 f64) (i64)";
            "b.m memory 2 5";
            ".t table funcref 3 -";
            "c.g global mut f32";
            "c.h global externref";
            "d.e func () ()";
            "d.u table externref 0 9";
            "x.v func (v128) (funcref)";
          ]
          (List.map import_text (Wasm_module.imports m));
        Alcotest.(check int) "import_count" 8 (Wasm_module.import_count m));
    case "a module with no import has no imports" (fun () ->
        Alcotest.(check int)
          "imports" 0
          (List.length (Wasm_module.imports (Lazy.force provider))));
    case "a store shares no memory with an instance of Instance" (fun () ->
        let m = Lazy.force provider in
        match Instance.create m generous with
        | Error f -> Alcotest.fail (failure_text f)
        | Ok solo ->
            Fun.protect
              ~finally:(fun () -> Instance.release solo)
              (fun () ->
                ok "write"
                  (Instance.write solo ~memory:"memory" ~address:3 "\x2a");
                with_store (fun store ->
                    let i = instantiate store m [] in
                    Alcotest.(check string)
                      "the byte in the store" "\x00"
                      (ok "read"
                         (Store.read store i ~memory:"memory" ~address:3
                            ~length:1)))));
  ]

let tests =
  module_cases @ link_cases @ limit_cases @ growth_cases @ memory_cases
  @ release_cases
