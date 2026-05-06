open Ast
open Context

let read_file path =
  let ic = open_in path in
  let n = in_channel_length ic in
  let s = Bytes.create n in
  really_input ic s 0 n;
  close_in ic;
  Bytes.to_string s

let parse_string s =
  Parser.main Lexer.token (Lexing.from_string s)

let run_file path =
  let filename = Filename.basename path in
  Printf.printf "\n=== %s ===\n" filename;
  let lines = String.split_on_char '\n' (read_file path) in
  let lines = List.filter (fun l -> String.trim l <> "") lines in
  let ctx = ref empty in
  List.iter (fun line ->
    let line = String.trim line in
    if String.length line >= 7 && String.sub line 0 7 = "assume " then begin
      let rest = String.sub line 7 (String.length line - 7) in
      match String.index_opt rest ':' with
      | Some i ->
        let name = String.trim (String.sub rest 0 i) in
        let type_str = String.trim (String.sub rest (i + 1) (String.length rest - i - 1)) in
        let ty = parse_string type_str in
        ctx := extend !ctx name ty;
        Printf.printf "  assumed %s : %s\n" name (string_of_expr ty)
      | None -> failwith ("Bad assume line: " ^ line)
    end
    else if String.length line >= 6 && String.sub line 0 6 = "infer " then begin
      let expr_str = String.sub line 6 (String.length line - 6) in
      let e = parse_string expr_str in
      Printf.printf "  expr: %s\n" (string_of_expr e);
      (try
        let ty = Typecheck.infer !ctx e in
        Printf.printf "  ACCEPT -- inferred type: %s\n" (string_of_expr ty)
      with Failure msg ->
        Printf.printf "  REJECT -- %s\n" msg)
    end
    else if String.length line >= 6 && String.sub line 0 6 = "equal " then begin
      let rest = String.sub line 6 (String.length line - 6) in
      match String.index_opt rest '=' with
      | Some i ->
        let lhs_str = String.trim (String.sub rest 0 i) in
        let rhs_str = String.trim (String.sub rest (i + 1) (String.length rest - i - 1)) in
        let lhs = parse_string lhs_str in
        let rhs = parse_string rhs_str in
        Printf.printf "  lhs: %s\n" (string_of_expr lhs);
        Printf.printf "  rhs: %s\n" (string_of_expr rhs);
        if Equal.equal lhs rhs then
          Printf.printf "  EQUAL\n"
        else
          Printf.printf "  NOT EQUAL\n"
      | None -> failwith ("Bad equal line, expected '=': " ^ line)
    end
    else
      failwith ("Unknown line: " ^ line)
  ) lines

let () =
  let dir = if Array.length Sys.argv > 1 then Sys.argv.(1) else "examples" in
  let files = Sys.readdir dir in
  Array.sort String.compare files;
  let files = Array.to_list files in
  let files = List.filter (fun f -> Filename.check_suffix f ".txt") files in
  Printf.printf "==================================================\n";
  Printf.printf "   Dependent Type Checker                         \n";
  Printf.printf "==================================================\n";
  List.iter (fun f -> run_file (Filename.concat dir f)) files;
  Printf.printf "\n=== Done ===\n"
