(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module W = Wasm_modules

let text ?(imports = "") ?(interface = "(i32.const 1)")
    ?(alloc = "(i32.const 16)") ?(recognise = "(i64.const 0)")
    ?(bind = "(i64.const 0)") ?(memory = "(memory 1)") rest =
  let memory_field =
    match String.index_opt memory ' ' with
    | Some i ->
        String.sub memory 0 i ^ " (export \"memory\")"
        ^ String.sub memory i (String.length memory - i)
    | None -> memory
  in
  W.of_text
    (String.concat "\n"
       [
         "(module";
         imports;
         memory_field;
         Printf.sprintf "(func (export \"sinter_interface\") (result i32) %s)"
           interface;
         Printf.sprintf
           "(func (export \"sinter_alloc\") (param $n i32) (result i32) %s)"
           alloc;
         Printf.sprintf
           "(func (export \"sinter_recognise\") (param $ra i32) (param $rn \
            i32) (param $ca i32) (param $cn i32) (result i64) %s)"
           recognise;
         Printf.sprintf
           "(func (export \"sinter_bind\") (param $ra i32) (param $rn i32) \
            (param $ca i32) (param $cn i32) (result i64) %s)"
           bind;
         rest;
         ")";
       ])

let all checks =
  List.fold_left
    (fun acc check -> Printf.sprintf "(i32.and %s %s)" acc check)
    "(i32.const 1)" checks

let core_2_features =
  [
    ( "fixed-width SIMD",
      text
        ~interface:
          (all
             [
               "(i32.eq (i32x4.extract_lane 2 (i32x4.add (v128.const i32x4 1 2 \
                3 4) (v128.const i32x4 10 20 30 40))) (i32.const 33))";
               "(i32.eq (i8x16.extract_lane_u 0 (i8x16.add (v128.const i8x16 \
                255 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) (v128.const i8x16 2 0 0 0 0 \
                0 0 0 0 0 0 0 0 0 0 0))) (i32.const 1))";
               "(block (result i32) (v128.store (i32.const 32) (i64x2.splat \
                (i64.const -1))) (i32.eq (i32.load (i32.const 44)) (i32.const \
                -1)))";
             ])
        "" );
    ( "bulk memory",
      text
        ~interface:
          (all
             [
               "(block (result i32) (memory.fill (i32.const 100) (i32.const \
                0xab) (i32.const 8)) (memory.copy (i32.const 200) (i32.const \
                100) (i32.const 8)) (memory.init $p (i32.const 300) (i32.const \
                1) (i32.const 2)) (data.drop $p) (memory.init $p (i32.const 0) \
                (i32.const 0) (i32.const 0)) (i32.const 1))";
               "(i32.eq (i32.load8_u (i32.const 207)) (i32.const 0xab))";
               "(i32.eq (i32.load8_u (i32.const 208)) (i32.const 0))";
               "(i32.eq (i32.load16_u (i32.const 300)) (i32.const 0x0302))";
             ])
        "(data $p \"\\01\\02\\03\")" );
    ( "reference types",
      text
        ~interface:
          (all
             [
               "(block (result i32) (table.set $e (i32.const 1) (ref.null \
                extern)) (ref.is_null (table.get $e (i32.const 1))))";
               "(i32.eq (table.size $e) (i32.const 2))";
               "(ref.is_null (select (result externref) (ref.null extern) \
                (global.get $g) (i32.const 0)))";
               "(block (result i32) (table.set $f (i32.const 1) (ref.func $h)) \
                (i32.eq (call_indirect $f (type $t) (i32.const 1)) (i32.const \
                7)))";
               "(i32.eqz (ref.is_null (ref.func $h)))";
             ])
        "(type $t (func (result i32))) (table $e 2 externref) (table $f 2 \
         funcref) (global $g (mut externref) (ref.null extern)) (elem declare \
         func $h) (func $h (result i32) (i32.const 7))" );
    ( "multiple values",
      text
        ~interface:
          "(i32.eq (block (result i32) (call $two) (block (param i32 i32) \
           (result i32) (i32.sub))) (i32.const -1))"
        "(func $two (result i32 i32) (i32.const 3) (i32.const 4))" );
    ( "sign extension",
      text
        ~interface:
          (all
             [
               "(i32.eq (i32.extend8_s (i32.const 0x80)) (i32.const -128))";
               "(i32.eq (i32.extend16_s (i32.const 0x7fff)) (i32.const 0x7fff))";
               "(i64.eq (i64.extend32_s (i64.const 0x80000000)) (i64.const \
                -2147483648))";
             ])
        "" );
    ( "saturating conversions",
      text
        ~interface:
          (all
             [
               "(i32.eqz (i32.trunc_sat_f32_s (f32.const nan)))";
               "(i32.eqz (i32.trunc_sat_f64_u (f64.const -1)))";
               "(i32.eq (i32.trunc_sat_f32_s (f32.const 3e10)) (i32.const \
                2147483647))";
               "(i64.eq (i64.trunc_sat_f64_s (f64.const -inf)) (i64.const \
                -9223372036854775808))";
             ])
        "" );
    ( "several tables",
      text
        ~interface:
          (all
             [
               "(block (result i32) (table.init $t1 $pe (i32.const 0) \
                (i32.const 0) (i32.const 1)) (elem.drop $pe) (table.copy $t1 \
                $t1 (i32.const 1) (i32.const 0) (i32.const 1)) (i32.const 1))";
               "(i32.eq (call_indirect $t1 (type $t) (i32.const 1)) (i32.const \
                9))";
               "(i32.eq (call_indirect $t0 (type $t) (i32.const 0)) (i32.const \
                5))";
             ])
        "(type $t (func (result i32))) (table $t0 1 funcref) (table $t1 2 \
         funcref) (elem (table $t0) (i32.const 0) func $five) (elem $pe func \
         $nine) (func $five (result i32) (i32.const 5)) (func $nine (result \
         i32) (i32.const 9))" );
    ( "export of a mutable global",
      text ~interface:"(global.set $g (i32.const 1)) (global.get $g)"
        "(global $g (export \"g\") (mut i32) (i32.const 0))" );
  ]

let v128_zero = "\xfd\x0c" ^ String.make 16 '\x00'

let later_proposals =
  let a = W.adapter in
  let b = W.base in
  [
    ("tail calls", a { b with feature = "\x12\x05"; extra_funcs = [ (3, "") ] });
    ("64-bit memories", a { b with memory = W.vec [ "\x04\x01" ] });
    ( "extended constant expressions",
      a { b with globals = [ "\x7f\x00\x41\x01\x41\x02\x6a\x0b" ] } );
    ( "exception tags",
      a { b with extra_sections = [ (13, W.vec [ "\x00\x03" ]) ] } );
    ( "exception handling with try_table",
      a { b with feature = "\x1f\x40\x00\x0b" } );
    ("legacy exception handling with try", a { b with feature = "\x06\x40\x0b" });
    ( "relaxed SIMD",
      a { b with feature = v128_zero ^ v128_zero ^ "\xfd\x80\x02\x1a" } );
    ("GC struct types", a { b with types = [ "\x5f\x00" ] });
    ("GC i31 references", a { b with feature = "\x41\x00\xfb\x1c\x1a" });
    ( "typed function references",
      a { b with types = [ "\x60\x01\x63\x00\x00" ] } );
    ("shared memories", a { b with memory = W.vec [ "\x03\x01\x01" ] });
    ( "atomic instructions",
      a { b with feature = "\x41\x00\xfe\x10\x02\x00\x1a" } );
    ( "wide arithmetic",
      a { b with feature = "\x42\x00\x42\x00\x42\x00\x42\x00\xfc\x13\x1a\x1a" }
    );
    ("custom page sizes", a { b with memory = W.vec [ "\x08\x01\x00" ] });
  ]

let bump =
  "(global $next (mut i32) (i32.const 4096)) (func $bump (param $n i32) \
   (result i32) (local $a i32) (local.set $a (global.get $next)) (global.set \
   $next (i32.add (global.get $next) (i32.add (local.get $n) (i32.const 8)))) \
   (local.get $a))"

let pointer address length =
  Printf.sprintf
    "(i64.or (i64.shl (i64.extend_i32_u %s) (i64.const 32)) (i64.extend_i32_u \
     %s))"
    address length

let data_string bytes =
  "\""
  ^ String.concat ""
      (List.init (String.length bytes) (fun i ->
           Printf.sprintf "\\%02x" (Char.code bytes.[i])))
  ^ "\""

let echo =
  let give = pointer "(local.get $ca)" "(local.get $cn)" in
  text ~memory:"(memory 16)" ~alloc:"(call $bump (local.get $n))"
    ~recognise:give ~bind:give bump

let responds response =
  if String.length response > 3000 then invalid_arg "Adapter_fixtures.responds";
  let give =
    pointer "(i32.const 1024)"
      (Printf.sprintf "(i32.const %d)" (String.length response))
  in
  text ~alloc:"(call $bump (local.get $n))" ~recognise:give ~bind:give
    (bump ^ Printf.sprintf " (data (i32.const 1024) %s)" (data_string response))

let request_is request =
  let length = String.length request in
  let answer yes no =
    Printf.sprintf
      "(if (result i64) (call $same (local.get $ra) (local.get $rn)) (then %s) \
       (else %s))"
      (pointer "(i32.const 64)"
         (string_of_int (String.length yes) |> Printf.sprintf "(i32.const %s)"))
      (pointer "(i32.const 512)"
         (string_of_int (String.length no) |> Printf.sprintf "(i32.const %s)"))
  in
  let recognise = answer {|{"recognised":true}|} {|{"recognised":false}|} in
  let bind_yes = {|{"bindings":[],"results":[],"warnings":[]}|} in
  let bind_no = {|{"error":"another request"}|} in
  let bind =
    Printf.sprintf
      "(if (result i64) (call $same (local.get $ra) (local.get $rn)) (then %s) \
       (else %s))"
      (pointer "(i32.const 1024)"
         (Printf.sprintf "(i32.const %d)" (String.length bind_yes)))
      (pointer "(i32.const 1536)"
         (Printf.sprintf "(i32.const %d)" (String.length bind_no)))
  in
  text ~memory:"(memory 4)" ~alloc:"(call $bump (local.get $n))" ~recognise
    ~bind
    (String.concat " "
       [
         bump;
         Printf.sprintf "(data (i32.const 64) %s)"
           (data_string {|{"recognised":true}|});
         Printf.sprintf "(data (i32.const 512) %s)"
           (data_string {|{"recognised":false}|});
         Printf.sprintf "(data (i32.const 1024) %s)" (data_string bind_yes);
         Printf.sprintf "(data (i32.const 1536) %s)" (data_string bind_no);
         Printf.sprintf "(data (i32.const 65536) %s)" (data_string request);
         Printf.sprintf
           "(func $same (param $a i32) (param $n i32) (result i32) (local $i \
            i32) (if (i32.ne (local.get $n) (i32.const %d)) (then (return \
            (i32.const 0)))) (block $done (loop $next (br_if $done (i32.ge_u \
            (local.get $i) (local.get $n))) (if (i32.ne (i32.load8_u (i32.add \
            (local.get $a) (local.get $i))) (i32.load8_u (i32.add (i32.const \
            65536) (local.get $i)))) (then (return (i32.const 0)))) (local.set \
            $i (i32.add (local.get $i) (i32.const 1))) (br $next))) (i32.const \
            1))"
           length;
       ])
