{
open Parser

let keyword_or_ident s =
  if String.length s > 4 && String.sub s 0 4 = "Type" then
    try TYPE (int_of_string (String.sub s 4 (String.length s - 4)))
    with Failure _ -> IDENT s
  else match s with
    | "Pi" -> PI | "Lambda" -> LAMBDA | "App" -> APP | "Ann" -> ANN
    | "Vec" -> VEC | "Mat" -> MAT | "Cons" -> CONS
    | "Fin" -> FIN | "Succ" -> SUCC
    | "Nat" -> NAT | "Zero" -> ZERO | "Nil" -> NIL
    | _ -> IDENT s
}

let white = [' ' '\t' '\n' '\r']
let letter = ['a'-'z' 'A'-'Z' '_']
let ident = letter (letter | ['0'-'9'])*

rule token = parse
  | white+      { token lexbuf }
  | '('         { LPAREN }
  | ')'         { RPAREN }
  | '.'         { DOT }
  | ':'         { COLON }
  | ident as s  { keyword_or_ident s }
  | eof         { EOF }
