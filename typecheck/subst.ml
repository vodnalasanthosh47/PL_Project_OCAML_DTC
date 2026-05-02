(** Capture-avoiding substitution. *)

open Ast

(** Fresh-name counter. *)
let gensym_counter = ref 0

(** [fresh x] returns a new name derived from [x]. *)
let fresh (x : string) : string =
  incr gensym_counter;
  Printf.sprintf "%s_%d" x !gensym_counter

(** Free variables of an expression. *)
let rec free_vars : expr -> string list = function
  | Var x -> [x]
  | Universe _ | Nat | Zero | Nil -> []
  | Succ n -> free_vars n
  | Fin n -> free_vars n
  | App (e1, e2) -> free_vars e1 @ free_vars e2
  | Ann (e, t) -> free_vars e @ free_vars t
  | Vec (a, n) -> free_vars a @ free_vars n
  | Cons (h, t) -> free_vars h @ free_vars t
  | Mat (m, n) -> free_vars m @ free_vars n
  | Pi (x, a, b) -> free_vars a @ List.filter (fun v -> v <> x) (free_vars b)
  | Lambda (x, t, body) -> free_vars t @ List.filter (fun v -> v <> x) (free_vars body)

(** Substitute [repl] for free occurrences of [Var x] in [target]. *)
let rec subst (x : string) (repl : expr) (target : expr) : expr =
  match target with
  | Var y ->
    if y = x then repl else Var y

  | Universe _ | Nat | Zero | Nil ->
    target

  | Succ n ->
    Succ (subst x repl n)

  | Fin n ->
    Fin (subst x repl n)

  | App (e1, e2) ->
    App (subst x repl e1, subst x repl e2)

  | Ann (e, t) ->
    Ann (subst x repl e, subst x repl t)

  | Vec (a, n) ->
    Vec (subst x repl a, subst x repl n)

  | Cons (h, t) ->
    Cons (subst x repl h, subst x repl t)

  | Mat (m, n) ->
    Mat (subst x repl m, subst x repl n)

  | Pi (y, a, b) ->
    subst_binder x repl y a b (fun y' a' b' -> Pi (y', a', b'))

  | Lambda (y, t, body) ->
    subst_binder x repl y t body (fun y' t' body' -> Lambda (y', t', body'))

(** Helper for substitution under binders. *)
and subst_binder x repl y ann body build =
  let ann' = subst x repl ann in
  if y = x then
    build y ann' body
  else if List.mem y (free_vars repl) then
    let y' = fresh y in
    let body' = subst y (Var y') body in
    build y' ann' (subst x repl body')
  else
    build y ann' (subst x repl body)
