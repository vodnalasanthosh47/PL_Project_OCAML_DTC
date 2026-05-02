(** Beta-reduction to normal form. *)

open Ast

(** Reduce [e] to normal form. *)
let rec normalize (e : expr) : expr =
  match e with
  (* Atomic expressions are already normal. *)
  | Var _ | Universe _ | Nat | Zero | Nil -> e

  (* Application. *)
  | App (e1, e2) ->
    let e1' = normalize e1 in
    let e2' = normalize e2 in
    (match e1' with
     | Lambda (x, _t, body) ->
      (* Beta-reduce the application. *)
       normalize (Subst.subst x e2' body)
     | _ ->
       App (e1', e2'))

  (* Normalize under binders. *)
  | Pi (x, a, b) ->
    Pi (x, normalize a, normalize b)

  | Lambda (x, t, body) ->
    Lambda (x, normalize t, normalize body)

  (* Normalize annotations. *)
  | Ann (e, t) ->
    Ann (normalize e, normalize t)

  (* Normalize recursive subexpressions. *)
  | Succ n ->
    Succ (normalize n)

  | Vec (a, n) ->
    Vec (normalize a, normalize n)

  | Cons (h, t) ->
    Cons (normalize h, normalize t)

  | Mat (m, n) ->
    Mat (normalize m, normalize n)

  | Fin n ->
    Fin (normalize n)
