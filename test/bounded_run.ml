(* SPDX-License-Identifier: Apache-2.0 *)
(* Copyright 2026 The Sinter Authors *)

let program = Filename.concat (Sys.getcwd ()) "wait_probe/wait_probe.exe"

let read_all descr =
  let buffer = Buffer.create 64 and chunk = Bytes.create 4096 in
  let rec loop () =
    match Unix.read descr chunk 0 (Bytes.length chunk) with
    | 0 -> ()
    | count ->
        Buffer.add_subbytes buffer chunk 0 count;
        loop ()
  in
  loop ();
  Buffer.contents buffer

let probe ~seconds args =
  let output, input = Unix.pipe ~cloexec:true () in
  let pid =
    Unix.create_process program
      (Array.of_list (program :: args))
      Unix.stdin input Unix.stderr
  in
  Unix.close input;
  let deadline = Unix.gettimeofday () +. seconds in
  let rec wait () =
    match Unix.waitpid [ Unix.WNOHANG ] pid with
    | 0, _ ->
        if Unix.gettimeofday () > deadline then None
        else (
          ignore (Unix.select [] [] [] 0.02);
          wait ())
    | _, status -> Some status
  in
  match wait () with
  | None ->
      (try Unix.kill pid Sys.sigkill with Unix.Unix_error _ -> ());
      ignore (Unix.waitpid [] pid);
      Unix.close output;
      Error (Printf.sprintf "no result within %g seconds" seconds)
  | Some (Unix.WEXITED 0) ->
      let text = read_all output in
      Unix.close output;
      Ok (List.filter (fun line -> line <> "") (String.split_on_char '\n' text))
  | Some _ ->
      Unix.close output;
      Error "the probe did not exit with the status 0"
