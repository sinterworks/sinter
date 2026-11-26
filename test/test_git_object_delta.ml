(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

module Gen = QCheck2.Gen
module Delta = Sinter_git_object_store.Delta
module O = Delta_data

let property ?(count = 300) ~name ~print generator check =
  QCheck_alcotest.to_alcotest ~speed_level:`Quick
    (QCheck2.Test.make ~count ~name ~print generator check)

let case name f = Alcotest.test_case name `Quick f

let error_name = function
  | Delta.Truncated -> "truncated"
  | Base_size_differs -> "base size differs"
  | Too_large -> "too large"
  | Copy_outside_base -> "copy outside base"
  | Reserved_instruction -> "reserved instruction"
  | Result_size_differs -> "result size differs"

let show = function
  | Ok bytes -> Printf.sprintf "Ok %S" bytes
  | Error error -> "Error " ^ error_name error

let check name expected actual =
  Alcotest.(check string) name (show expected) (show actual)

let big = 1 lsl 40

let data base result instructions =
  O.delta ~base_size:(String.length base) ~result_size:(String.length result)
    instructions

let base_gen = Gen.string_size ~gen:Gen.char (Gen.int_range 1 400)

let instructions_gen base =
  let length = String.length base in
  let copy =
    Gen.(
      int_range 0 (length - 1) >>= fun offset ->
      int_range 1 (length - offset) >|= fun size -> O.Copy (offset, size))
  in
  let insert =
    Gen.map
      (fun data -> O.Insert data)
      (Gen.string_size ~gen:Gen.char (Gen.int_range 1 127))
  in
  Gen.list_size (Gen.int_range 0 12) (Gen.oneof [ copy; insert ])

let print_case (base, instructions) =
  Printf.sprintf "base %S, delta %S" base
    (O.delta ~base_size:(String.length base) ~result_size:0 instructions)

let decode_size text start =
  let rec go at shift value =
    if at >= String.length text then None
    else
      let byte = Char.code text.[at] in
      let value = value lor ((byte land 0x7f) lsl shift) in
      if byte land 0x80 = 0 then Some (value, at + 1)
      else if shift > 56 then None
      else go (at + 1) (shift + 7) value
  in
  go start 0 0

let apply_tests =
  [
    property ~name:"apply gives the bytes that the instructions copy and add"
      ~print:print_case
      Gen.(base_gen >>= fun base -> pair (return base) (instructions_gen base))
      (fun (base, instructions) ->
        let result = O.apply base instructions in
        Delta.apply ~max_size:big ~base (data base result instructions)
        = Ok result);
    property
      ~name:"apply of a delta between two byte sequences gives the second"
      ~print:(fun (a, b) -> Printf.sprintf "%S %S" a b)
      Gen.(pair base_gen (string_size ~gen:char (int_range 0 400)))
      (fun (base, target) ->
        Delta.apply ~max_size:big ~base
          (data base target (O.delta_between base target))
        = Ok target);
    case "a copy with no size byte copies 65536 bytes" (fun () ->
        let base = String.init 70000 (fun i -> Char.chr (i mod 251)) in
        let result = String.sub base 1 65536 in
        check "the size 0x10000" (Ok result)
          (Delta.apply ~max_size:big ~base
             (O.delta ~base_size:70000 ~result_size:65536
                [ O.Raw_instruction "\x81\x01" ])));
    case "a copy with no offset byte and no size byte copies 65536 bytes from 0"
      (fun () ->
        let base = String.init 65536 (fun i -> Char.chr (i mod 13)) in
        check "0x80" (Ok base)
          (Delta.apply ~max_size:big ~base
             (O.delta ~base_size:65536 ~result_size:65536
                [ O.Raw_instruction "\x80" ])));
    case "each present offset and size byte keeps its place" (fun () ->
        let base = String.init 0x30000 (fun i -> Char.chr (i mod 241)) in
        let offset = 0x020005 and size = 0x000103 in
        check "offset bytes 1 and 3, size bytes 1 and 2"
          (Ok (String.sub base offset size))
          (Delta.apply ~max_size:big ~base
             (O.delta ~base_size:0x30000 ~result_size:size
                [ O.Raw_instruction "\xb5\x05\x02\x03\x01" ])));
    case "the fourth offset byte and the third size byte keep their places"
      (fun () ->
        let length = 0x1020000 in
        let base =
          String.init length (fun i -> Char.chr ((i lsr 3) land 0xff))
        in
        let offset = 0x01000002 and size = 0x010003 in
        check "offset bytes 1 and 4, size bytes 1 and 3"
          (Ok (String.sub base offset size))
          (Delta.apply ~max_size:big ~base
             (O.delta ~base_size:length ~result_size:size
                [ O.Raw_instruction "\xd9\x02\x01\x03\x01" ])));
    case "a size with zero bits past bit 63 is its value" (fun () ->
        let overlong n =
          String.make 1 (Char.chr (0x80 lor n)) ^ String.make 8 '\x80' ^ "\x00"
        in
        check "base size 3 and result size 2" (Ok "ab")
          (Delta.apply ~max_size:big ~base:"abc"
             (overlong 3 ^ overlong 2 ^ "\x02ab")));
    case "a result size with bits at 2^62 and above is too large" (fun () ->
        List.iter
          (fun size ->
            check (String.escaped size) (Error Too_large)
              (Delta.apply ~max_size:max_int ~base:"abc"
                 ("\x03" ^ size ^ "\x03abc")))
          [
            String.make 8 '\x80' ^ "\x40";
            String.make 8 '\x80' ^ "\x7f";
            String.make 9 '\x80' ^ "\x01";
          ]);
    case "a base size with bits at 2^62 and above differs from the base"
      (fun () ->
        check "2^62" (Error Base_size_differs)
          (Delta.apply ~max_size:max_int ~base:"abc"
             (String.make 8 '\x80' ^ "\x40" ^ "\x03\x03abc")));
    case "an empty result needs no instruction" (fun () ->
        check "empty" (Ok "")
          (Delta.apply ~max_size:0 ~base:"abc"
             (O.delta ~base_size:3 ~result_size:0 [])));
    case "an add of 127 bytes adds them" (fun () ->
        let bytes = String.make 127 'q' in
        check "127" (Ok bytes)
          (Delta.apply ~max_size:big ~base:"x"
             (O.delta ~base_size:1 ~result_size:127 [ O.Insert bytes ])));
  ]

let errors =
  let d = O.delta in
  [
    ("no bytes", "abc", "", Delta.Truncated);
    ("a base size that does not end", "abc", "\x83", Delta.Truncated);
    ( "a base size that differs",
      "abc",
      d ~base_size:4 ~result_size:1 [ O.Insert "a" ],
      Base_size_differs );
    ("no result size", "abc", "\x03", Truncated);
    ("a result size that does not end", "abc", "\x03\x81", Truncated);
    ("a copy whose offset bytes are cut", "abc", "\x03\x02\x81", Truncated);
    ("a copy whose size bytes are cut", "abc", "\x03\x02\x90", Truncated);
    ("an add whose bytes are cut", "abc", "\x03\x03\x03ab", Truncated);
    ("a reserved instruction", "abc", "\x03\x01\x00", Reserved_instruction);
    ( "a copy after the end of the base",
      "abc",
      d ~base_size:3 ~result_size:1 [ O.Copy (3, 1) ],
      Copy_outside_base );
    ( "a copy past the end of the base",
      "abc",
      d ~base_size:3 ~result_size:3 [ O.Copy (1, 3) ],
      Copy_outside_base );
    ( "a copy whose offset is far outside",
      "abc",
      d ~base_size:3 ~result_size:1
        [ O.Raw_instruction "\x9f\xff\xff\xff\xff\x01" ],
      Copy_outside_base );
    ( "instructions that give more",
      "abc",
      d ~base_size:3 ~result_size:2 [ O.Insert "abc" ],
      Result_size_differs );
    ( "a copy that gives more",
      "abc",
      d ~base_size:3 ~result_size:2 [ O.Copy (0, 3) ],
      Result_size_differs );
    ( "instructions that give fewer",
      "abc",
      d ~base_size:3 ~result_size:4 [ O.Copy (0, 3) ],
      Result_size_differs );
    ( "no instruction for a result of one byte",
      "abc",
      d ~base_size:3 ~result_size:1 [],
      Result_size_differs );
  ]

let order_cases =
  let d = O.delta in
  [
    ( "the base size before the result size",
      "abc",
      "\x04\x83",
      Delta.Base_size_differs );
    ( "the base size before an instruction",
      "abc",
      d ~base_size:2 ~result_size:1 [ O.Raw_instruction "\x00" ],
      Base_size_differs );
    ( "a result size above the maximum before a cut instruction",
      "abc",
      d ~base_size:3 ~result_size:11 [ O.Raw_instruction "\x05a" ],
      Too_large );
    ( "a result size above the maximum before a reserved instruction",
      "abc",
      d ~base_size:3 ~result_size:11 [ O.Raw_instruction "\x00" ],
      Too_large );
    ( "the first instruction first",
      "abc",
      d ~base_size:3 ~result_size:2 [ O.Raw_instruction "\x00"; O.Copy (5, 1) ],
      Reserved_instruction );
    ( "a copy outside before a reserved instruction",
      "abc",
      d ~base_size:3 ~result_size:2 [ O.Copy (5, 1); O.Raw_instruction "\x00" ],
      Copy_outside_base );
    ( "too many bytes before a later reserved instruction",
      "abc",
      d ~base_size:3 ~result_size:1 [ O.Insert "ab"; O.Raw_instruction "\x00" ],
      Result_size_differs );
    ( "too many bytes before a later cut instruction",
      "abc",
      d ~base_size:3 ~result_size:1 [ O.Insert "ab"; O.Raw_instruction "\x05" ],
      Result_size_differs );
  ]

(* @cites changes#commit=v1
   Delta.apply checks each instruction in order. When an instruction would
   give more bytes than the stated result size, Delta.apply returns
   Error Result_size_differs before Delta.apply checks any later instruction. *)
let later_copy_past_result_size =
  case
    "apply gives result size differs when a later copy passes the result size"
    (fun () ->
      let base = "abc" in
      let check_case label instructions =
        check label (Error Result_size_differs)
          (Delta.apply ~max_size:10 ~base
             (O.delta ~base_size:3 ~result_size:2 instructions))
      in
      check_case "a second copy past the result size"
        [ O.Copy (0, 1); O.Copy (1, 2) ];
      check_case "a copy after an insert past the result size"
        [ O.Insert "a"; O.Copy (0, 2) ];
      check_case
        "a later copy past the result size before a reserved instruction"
        [ O.Copy (0, 1); O.Copy (1, 2); O.Raw_instruction "\x00" ])

let error_tests =
  List.map
    (fun (name, base, delta, expected) ->
      case
        ("apply gives " ^ error_name expected ^ " for " ^ name)
        (fun () ->
          check name (Error expected) (Delta.apply ~max_size:10 ~base delta)))
    errors
  @ List.map
      (fun (name, base, delta, expected) ->
        case ("apply checks " ^ name) (fun () ->
            check name (Error expected) (Delta.apply ~max_size:10 ~base delta)))
      order_cases
  @ [ later_copy_past_result_size ]

let max_size_tests =
  [
    case "a result of the maximum size is given, and one byte more is too large"
      (fun () ->
        let base = "0123456789" in
        let delta n = O.delta ~base_size:10 ~result_size:n [ O.Copy (0, n) ] in
        check "at the maximum" (Ok "01234567")
          (Delta.apply ~max_size:8 ~base (delta 8));
        check "above the maximum" (Error Too_large)
          (Delta.apply ~max_size:7 ~base (delta 8)));
    case "a result size above the longest string is too large" (fun () ->
        check "with no maximum" (Error Too_large)
          (Delta.apply ~max_size:max_int ~base:"abc"
             (O.delta ~base_size:3
                ~result_size:(Sys.max_string_length + 1)
                [ O.Copy (0, 3) ])));
    case "the time of apply grows linearly with the delta and the result"
      (fun () ->
        let time n =
          let base = String.init 256 Char.chr in
          let delta =
            O.delta ~base_size:256 ~result_size:n
              (List.init n (fun i -> O.Copy (i land 255, 1)))
          in
          let best = ref infinity in
          for _ = 1 to 5 do
            let start = Sys.time () in
            (match Delta.apply ~max_size:n ~base delta with
            | Ok result -> assert (String.length result = n)
            | Error _ -> Alcotest.fail "no result");
            best := Float.min !best (Sys.time () -. start)
          done;
          !best
        in
        let small = time 200_000 and large = time 800_000 in
        Alcotest.(check bool)
          (Printf.sprintf "%.4f s for n, %.4f s for 4n" small large)
          true
          (large <= (8. *. small) +. 0.002));
    case "a negative maximum size raises Invalid_argument" (fun () ->
        match Delta.apply ~max_size:(-1) ~base:"" "\x00\x00" with
        | exception Invalid_argument _ -> ()
        | _ -> Alcotest.fail "no Invalid_argument");
    case
      "instructions that give far more than the result size take no memory for \
       them" (fun () ->
        let base = String.make 65536 'b' in
        let delta =
          O.delta ~base_size:65536 ~result_size:1
            (List.init 2000 (fun _ -> O.Raw_instruction "\x80"))
        in
        let before = Gc.allocated_bytes () in
        let result = Delta.apply ~max_size:big ~base delta in
        let taken = Gc.allocated_bytes () -. before in
        check "the result" (Error Result_size_differs) result;
        Alcotest.(check bool)
          (Printf.sprintf "%.0f bytes taken for 131 MB of copies" taken)
          true (taken < 16_000_000.));
  ]

let corrupted_gen =
  Gen.(
    base_gen >>= fun base ->
    instructions_gen base >>= fun instructions ->
    let valid = data base (O.apply base instructions) instructions in
    oneof
      [
        map
          (fun cut ->
            (base, String.sub valid 0 (cut mod (String.length valid + 1))))
          nat;
        map
          (fun (at, byte) ->
            let at = at mod String.length valid in
            (base, String.mapi (fun i c -> if i = at then byte else c) valid))
          (pair nat char);
        map
          (fun noise -> (base, noise))
          (string_size ~gen:char (int_range 0 40));
        map
          (fun (at, extra) ->
            let at = at mod (String.length valid + 1) in
            ( base,
              String.sub valid 0 at ^ extra
              ^ String.sub valid at (String.length valid - at) ))
          (pair nat (string_size ~gen:char (int_range 1 8)));
      ])

let corrupted_properties =
  [
    property ~count:1000
      ~name:"apply of any bytes gives a result of the stated size or an error"
      ~print:(fun (base, delta) ->
        Printf.sprintf "base %S, delta %S" base delta)
      corrupted_gen
      (fun (base, delta) ->
        match Delta.apply ~max_size:300 ~base delta with
        | Error _ -> true
        | Ok result -> (
            match decode_size delta 0 with
            | None -> false
            | Some (_, next) -> (
                match decode_size delta next with
                | None -> false
                | Some (size, _) -> String.length result = size && size <= 300)));
  ]

let tests = apply_tests @ error_tests @ max_size_tests @ corrupted_properties
