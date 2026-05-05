(** ast.ml -- Abstract syntax for a minimal dependent type theory.*)

(** The core expression type. Every term and every type is an [expr]. *)
type expr =
  | Var of string                    (** Variables *)
  | Universe of int                  (** Type0, Type1, ... (universe hierarchy) *)
  | Pi of string * expr * expr       (** Pi(x : A). B  -- dependent product *)
  | Lambda of string * expr * expr   (** Lambda(x : A). body *)
  | App of expr * expr               (** f arg  -- application *)
  | Ann of expr * expr               (** (e : T) -- type annotation for inference *)
  | Nat                              (** The type of natural numbers *)
  | Zero                             (** 0 : Nat *)
  | Succ of expr                     (** succ n : Nat *)
  | Vec of expr * expr               (** Vec A n -- length-indexed vector *)
  | Nil                              (** [] : Vec A Zero *)
  | Cons of expr * expr              (** h :: t : Vec A (Succ n) *)
  | Mat of expr * expr               (** Mat m n -- mxn matrix type *)
  | Fin of expr                      (** Fin n -- bounded natural < n *)

(** Pretty-print an expression for error messages. *)
let rec string_of_expr = function
  | Var x -> x
  | Universe k -> Printf.sprintf "Type%d" k
  | Pi (x, a, b) ->
    Printf.sprintf "(Pi(%s : %s). %s)" x (string_of_expr a) (string_of_expr b)
  | Lambda (x, t, body) ->
    Printf.sprintf "(Lambda(%s : %s). %s)" x (string_of_expr t) (string_of_expr body)
  | App (f, arg) ->
    Printf.sprintf "(%s %s)" (string_of_expr f) (string_of_expr arg)
  | Ann (e, t) ->
    Printf.sprintf "(%s : %s)" (string_of_expr e) (string_of_expr t)
  | Nat -> "Nat"
  | Zero -> "Zero"
  | Succ n -> Printf.sprintf "(Succ %s)" (string_of_expr n)
  | Vec (a, n) ->
    Printf.sprintf "(Vec %s %s)" (string_of_expr a) (string_of_expr n)
  | Nil -> "Nil"
  | Cons (h, t) ->
    Printf.sprintf "(Cons %s %s)" (string_of_expr h) (string_of_expr t)
  | Mat (m, n) ->
    Printf.sprintf "(Mat %s %s)" (string_of_expr m) (string_of_expr n)
  | Fin n -> Printf.sprintf "(Fin %s)" (string_of_expr n)
