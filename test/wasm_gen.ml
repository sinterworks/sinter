(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen

type ty = I32 | I64 | F32 | F64 | V128

let ty_name = function
  | I32 -> "i32"
  | I64 -> "i64"
  | F32 -> "f32"
  | F64 -> "f64"
  | V128 -> "v128"

type env = {
  locals : (int * ty) list;
  globals : (int * ty * bool) list;
  helpers : (int * ty list * ty list) list;
  ill_typed : bool;
}

let ( let* ) = Gen.( >>= )
let ( and* ) a b = Gen.pair a b
let pick = Gen.oneof_list
let all_types = [ I32; I64; F32; F64; V128 ]

let constant = function
  | I32 ->
      Gen.map
        (Printf.sprintf "(i32.const %ld)")
        (Gen.oneof
           [
             pick
               [
                 0l;
                 1l;
                 -1l;
                 2l;
                 16l;
                 65535l;
                 65536l;
                 Int32.max_int;
                 Int32.min_int;
               ];
             Gen.int32;
           ])
  | I64 ->
      Gen.map
        (Printf.sprintf "(i64.const %Ld)")
        (Gen.oneof
           [ pick [ 0L; 1L; -1L; Int64.max_int; Int64.min_int ]; Gen.int64 ])
  | F32 ->
      Gen.map
        (Printf.sprintf "(f32.const %s)")
        (pick
           [ "0"; "-0"; "1.5"; "-2"; "inf"; "-inf"; "nan"; "3e38"; "0x1p-149" ])
  | F64 ->
      Gen.map
        (Printf.sprintf "(f64.const %s)")
        (pick [ "0"; "-0"; "1.5"; "-2"; "inf"; "nan"; "1e308"; "4294967296" ])
  | V128 ->
      let* a = Gen.int32 and* b = Gen.int32 and* c = Gen.nat_small in
      Gen.return (Printf.sprintf "(v128.const i32x4 %ld %ld %d 0)" a b c)

let address =
  Gen.map
    (Printf.sprintf "(i32.const %d)")
    (Gen.oneof_weighted
       [
         (12, Gen.int_bound 64);
         (1, pick [ 65532; 65535; 65536; 131068; 262140 ]);
       ])

let length =
  Gen.oneof_weighted [ (8, Gen.int_bound 64); (1, Gen.int_bound 70000) ]

let rec expr env depth ty =
  let leaves =
    constant ty
    :: List.filter_map
         (fun (i, t) ->
           if t = ty then Some (Gen.return (Printf.sprintf "(local.get %d)" i))
           else None)
         env.locals
    @ List.filter_map
        (fun (i, t, _) ->
          if t = ty then Some (Gen.return (Printf.sprintf "(global.get %d)" i))
          else None)
        env.globals
  in
  if depth <= 0 then Gen.oneof leaves
  else
    let sub t = Gen.delay (fun () -> expr env (depth - 1) t) in
    let un op t = Gen.map (Printf.sprintf "(%s %s)" op) (sub t) in
    let bin op t =
      let* a = sub t and* b = sub t in
      Gen.return (Printf.sprintf "(%s %s %s)" op a b)
    in
    let calls =
      List.filter_map
        (fun (i, params, results) ->
          if results = [ ty ] then
            Some
              (let* args = Gen.flatten_list (List.map sub params) in
               Gen.return
                 (Printf.sprintf "(call %d %s)" i (String.concat " " args)))
          else None)
        env.helpers
    in
    let common =
      [
        (let* c = sub I32 and* a = sub ty and* b = sub ty in
         Gen.return (Printf.sprintf "(select %s %s %s)" a b c));
        (let* c = sub I32 and* a = sub ty and* b = sub ty in
         Gen.return
           (Printf.sprintf "(if (result %s) %s (then %s) (else %s))"
              (ty_name ty) c a b));
        (let* s = Gen.delay (fun () -> statement env (depth - 1))
         and* a = sub ty in
         Gen.return
           (Printf.sprintf "(block (result %s) %s %s)" (ty_name ty) s a));
      ]
    in
    let own =
      match ty with
      | I32 ->
          [
            (let* op =
               pick
                 [
                   "i32.add";
                   "i32.sub";
                   "i32.mul";
                   "i32.div_s";
                   "i32.div_u";
                   "i32.rem_s";
                   "i32.rem_u";
                   "i32.and";
                   "i32.or";
                   "i32.xor";
                   "i32.shl";
                   "i32.shr_s";
                   "i32.shr_u";
                   "i32.rotl";
                   "i32.rotr";
                   "i32.eq";
                   "i32.ne";
                   "i32.lt_s";
                   "i32.lt_u";
                   "i32.ge_u";
                 ]
             in
             bin op I32);
            (let* op =
               pick
                 [
                   "i32.clz";
                   "i32.ctz";
                   "i32.popcnt";
                   "i32.eqz";
                   "i32.extend8_s";
                   "i32.extend16_s";
                 ]
             in
             un op I32);
            (let* op = pick [ "i64.eq"; "i64.lt_u"; "i64.gt_s" ] in
             bin op I64);
            (let* op = pick [ "f32.eq"; "f32.lt"; "f32.ge" ] in
             bin op F32);
            (let* op = pick [ "f64.ne"; "f64.gt"; "f64.le" ] in
             bin op F64);
            un "i32.wrap_i64" I64;
            un "i64.eqz" I64;
            un "i32.trunc_sat_f32_s" F32;
            un "i32.trunc_sat_f64_u" F64;
            un "i32.trunc_f32_s" F32;
            un "i32.trunc_f64_u" F64;
            Gen.map (Printf.sprintf "(i32.load %s)") address;
            Gen.map (Printf.sprintf "(i32.load8_u offset=3 %s)") address;
            Gen.map (Printf.sprintf "(i32.load16_s %s)") address;
            Gen.return "(memory.size)";
            Gen.return "(ref.is_null (ref.null extern))";
            Gen.return "(ref.is_null (ref.null func))";
            (let* lane = Gen.int_bound 3 in
             Gen.map
               (Printf.sprintf "(i32x4.extract_lane %d %s)" lane)
               (sub V128));
            un "v128.any_true" V128;
            un "i8x16.all_true" V128;
          ]
      | I64 ->
          [
            (let* op =
               pick
                 [
                   "i64.add";
                   "i64.mul";
                   "i64.div_s";
                   "i64.rem_u";
                   "i64.shl";
                   "i64.and";
                   "i64.rotr";
                 ]
             in
             bin op I64);
            (let* op = pick [ "i64.extend_i32_s"; "i64.extend_i32_u" ] in
             un op I32);
            un "i64.extend32_s" I64;
            un "i64.popcnt" I64;
            un "i64.trunc_sat_f64_s" F64;
            un "i64.trunc_f32_u" F32;
            Gen.map (Printf.sprintf "(i64.load %s)") address;
            Gen.map (Printf.sprintf "(i64.load32_u %s)") address;
            un "i64x2.extract_lane 1" V128;
          ]
      | F32 ->
          [
            (let* op =
               pick
                 [
                   "f32.add";
                   "f32.sub";
                   "f32.mul";
                   "f32.div";
                   "f32.min";
                   "f32.max";
                 ]
             in
             bin op F32);
            (let* op =
               pick
                 [ "f32.sqrt"; "f32.neg"; "f32.abs"; "f32.ceil"; "f32.nearest" ]
             in
             un op F32);
            un "f32.convert_i32_s" I32;
            un "f32.convert_i64_u" I64;
            un "f32.demote_f64" F64;
          ]
      | F64 ->
          [
            (let* op = pick [ "f64.add"; "f64.mul"; "f64.div"; "f64.max" ] in
             bin op F64);
            (let* op = pick [ "f64.floor"; "f64.trunc"; "f64.neg" ] in
             un op F64);
            un "f64.convert_i32_u" I32;
            un "f64.promote_f32" F32;
          ]
      | V128 ->
          [
            (let* op =
               pick
                 [
                   "i32x4.add";
                   "i8x16.sub";
                   "i16x8.mul";
                   "v128.and";
                   "v128.xor";
                   "i8x16.eq";
                 ]
             in
             bin op V128);
            un "v128.not" V128;
            un "i32x4.splat" I32;
            un "i64x2.splat" I64;
            (let* lane = Gen.int_bound 15 in
             let* a = sub V128 and* b = sub I32 in
             Gen.return
               (Printf.sprintf "(i8x16.replace_lane %d %s %s)" lane a b));
            Gen.map (Printf.sprintf "(v128.load %s)") address;
          ]
    in
    let wrong =
      if env.ill_typed then
        [
          (let* other = pick (List.filter (fun t -> t <> ty) all_types) in
           sub other);
        ]
      else []
    in
    Gen.oneof_weighted
      (List.map (fun g -> (4, g)) leaves
      @ List.map (fun g -> (3, g)) own
      @ List.map (fun g -> (2, g)) (common @ calls)
      @ List.map (fun g -> (1, g)) wrong)

and statement env depth =
  let sub t = Gen.delay (fun () -> expr env depth t) in
  let stores =
    [
      (let* a = address and* v = sub I32 in
       Gen.return (Printf.sprintf "(i32.store %s %s)" a v));
      (let* a = address and* v = sub I64 in
       Gen.return (Printf.sprintf "(i64.store8 %s %s)" a v));
      (let* a = address and* v = sub V128 in
       Gen.return (Printf.sprintf "(v128.store %s %s)" a v));
      (let* d = address and* v = sub I32 and* n = length in
       Gen.return (Printf.sprintf "(memory.fill %s %s (i32.const %d))" d v n));
      (let* d = address and* s = address and* n = length in
       Gen.return (Printf.sprintf "(memory.copy %s %s (i32.const %d))" d s n));
      (let* t = pick all_types in
       Gen.map (Printf.sprintf "(drop %s)") (expr env depth t));
      Gen.return "(nop)";
    ]
  in
  let sets =
    List.map
      (fun (i, t) -> Gen.map (Printf.sprintf "(local.set %d %s)" i) (sub t))
      env.locals
    @ List.filter_map
        (fun (i, t, mutable_) ->
          if mutable_ then
            Some (Gen.map (Printf.sprintf "(global.set %d %s)" i) (sub t))
          else None)
        env.globals
  in
  let calls =
    List.map
      (fun (i, params, results) ->
        let* args = Gen.flatten_list (List.map sub params) in
        Gen.return
          (Printf.sprintf "(call %d %s) %s" i (String.concat " " args)
             (String.concat " " (List.map (fun _ -> "drop") results))))
      env.helpers
  in
  Gen.oneof_weighted
    ((1, Gen.return "(unreachable)")
    :: List.map (fun g -> (8, g)) (stores @ sets @ calls))

let statements env depth =
  let* n = Gen.int_bound 3 in
  Gen.map (String.concat " ")
    (Gen.list_size (Gen.return n) (statement env depth))

let types n = Gen.list_size (Gen.int_bound n) (pick all_types)

let decls keyword offset tys =
  String.concat " "
    (List.mapi
       (fun i t ->
         Printf.sprintf "(%s $%s%d %s)" keyword keyword (offset + i) (ty_name t))
       tys)

let func_body env results =
  let* body = statements env 2 in
  let* tail = Gen.flatten_list (List.map (expr env 3) results) in
  Gen.return (body ^ " " ^ String.concat " " tail)

let indexed offset tys = List.mapi (fun i t -> (offset + i, t)) tys

let module_text =
  let* ill_typed = Gen.map (fun k -> k = 0) (Gen.int_bound 9) in
  let* global_types = types 3 in
  let* mutables =
    Gen.list_size (Gen.return (List.length global_types)) Gen.bool
  in
  let globals_env =
    List.mapi (fun i (t, m) -> (i, t, m)) (List.combine global_types mutables)
  in
  let* globals_text =
    Gen.flatten_list
      (List.map
         (fun (_, t, m) ->
           let* init = constant t in
           Gen.return
             (if m then Printf.sprintf "(global (mut %s) %s)" (ty_name t) init
              else Printf.sprintf "(global %s %s)" (ty_name t) init))
         globals_env)
  in
  let* import = Gen.map (fun k -> k = 0) (Gen.int_bound 11) in
  let first = if import then 1 else 0 in
  let* helper_count = Gen.int_bound 4 in
  let rec helpers i acc =
    if i = helper_count then Gen.return (List.rev acc)
    else
      let* params = types 3 and* results = types 2 and* local_types = types 3 in
      let index = first + i in
      let env =
        {
          locals = indexed 0 (params @ local_types);
          globals = globals_env;
          helpers = List.map (fun (j, p, r, _) -> (j, p, r)) acc;
          ill_typed;
        }
      in
      let* body = func_body env results in
      let text =
        Printf.sprintf "(func %s %s %s %s)" (decls "param" 0 params)
          (if results = [] then ""
           else "(result " ^ String.concat " " (List.map ty_name results) ^ ")")
          (decls "local" (List.length params) local_types)
          body
      in
      helpers (i + 1) ((index, params, results, text) :: acc)
  in
  let* helper_list = helpers 0 [] in
  let callable = List.map (fun (j, p, r, _) -> (j, p, r)) helper_list in
  let top local_types =
    {
      locals = indexed 0 local_types;
      globals = globals_env;
      helpers = callable;
      ill_typed;
    }
  in
  let* interface_locals = types 3 in
  let* interface_body =
    Gen.oneof_weighted
      [
        ( 3,
          let* s = statements (top interface_locals) 2 in
          Gen.return (s ^ " (i32.const 1)") );
        (1, func_body (top interface_locals) [ I32 ]);
      ]
  in
  let* start_locals = types 2 in
  let* start =
    Gen.oneof_weighted
      [
        (2, Gen.return None);
        (1, Gen.map Option.some (statements (top start_locals) 2));
      ]
  in
  let* maximum =
    Gen.oneof [ Gen.return ""; Gen.map string_of_int (Gen.int_range 1 4) ]
  in
  let* data =
    Gen.list_size (Gen.int_bound 2)
      (let* offset =
         Gen.oneof_weighted [ (12, Gen.int_bound 64); (1, Gen.return 65530) ]
       and* bytes = Gen.list_size (Gen.int_bound 16) (Gen.int_bound 255) in
       Gen.return
         (Printf.sprintf "(data (i32.const %d) \"%s\")" offset
            (String.concat "" (List.map (Printf.sprintf "\\%02x") bytes))))
  in
  let* func_table =
    if helper_list = [] then Gen.return ""
    else
      let* size = Gen.int_range 1 4 in
      let names = List.map (fun (j, _, _, _) -> string_of_int j) helper_list in
      let elems = List.filteri (fun i _ -> i < size) names in
      Gen.return
        (Printf.sprintf "(table %d funcref) (elem (i32.const 0) func %s)" size
           (String.concat " " elems))
  in
  let* extern_table = pick [ ""; "(table 2 externref)" ] in
  let* broken_export =
    Gen.oneof_weighted
      [ (8, Gen.return None); (1, Gen.map Option.some (Gen.int_bound 4)) ]
  in
  let export k name = if broken_export = Some k then name ^ "_" else name in
  let* alloc_param =
    Gen.oneof_weighted [ (12, Gen.return "i32"); (1, Gen.return "i64") ]
  in
  let start_text =
    match start with
    | None -> ""
    | Some body ->
        Printf.sprintf "(func $start %s %s) (start $start)"
          (decls "local" 0 start_locals)
          body
  in
  Gen.return
    (String.concat "\n"
       [
         "(module";
         (if import then "(import \"env\" \"f\" (func))" else "");
         String.concat "\n" (List.map (fun (_, _, _, t) -> t) helper_list);
         Printf.sprintf "(func (export %S) (result i32) %s %s)"
           (export 0 "sinter_interface")
           (decls "local" 0 interface_locals)
           interface_body;
         Printf.sprintf
           "(func (export %S) (param %s) (result i32) (i32.const 16))"
           (export 1 "sinter_alloc") alloc_param;
         Printf.sprintf
           "(func (export %S) (param i32 i32 i32 i32) (result i64) (i64.const \
            0))"
           (export 2 "sinter_recognise");
         Printf.sprintf
           "(func (export %S) (param i32 i32 i32 i32) (result i64) (i64.const \
            0))"
           (export 3 "sinter_bind");
         start_text;
         Printf.sprintf "(memory (export %S) 1 %s)" (export 4 "memory") maximum;
         String.concat "\n" globals_text;
         func_table;
         extern_table;
         String.concat "\n" data;
         ")";
       ])
