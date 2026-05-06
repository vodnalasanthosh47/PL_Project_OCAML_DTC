(** typecheck.ml -- Bidirectional type checking for dependent types. *)

module Typecheck = struct

open Ast
open Context

(** [type_error msg] raises a type error with the given message. *)
let type_error msg =
  failwith (Printf.sprintf "Type error: %s" msg)

(** Infers the type of [e] in context [ctx]. *)
let rec infer (ctx : context) (e : expr) : expr =
  match e with
  | Var x ->
    lookup ctx x

  | Universe k ->
    Universe (k + 1)

  | Pi (x, a, b) ->
    let k1 = infer_universe ctx a in
    let k2 = infer_universe (extend ctx x a) b in
    Universe (max k1 k2)

  | Lambda (_x, _t, _body) ->
    type_error (Printf.sprintf
      "Cannot infer the type of a bare lambda: %s\n\
       Hint: wrap it in a type annotation, e.g. (e : T)"
      (string_of_expr e))

  | App (f, arg) ->
    let ft = infer ctx f in
    (match Normalizer.normalize ft with
     | Pi (x, s, t) ->
       check ctx arg s;
       Subst.subst x arg t
     | _ ->
       type_error (Printf.sprintf
         "Expected a function type, but %s has type %s"
         (string_of_expr f) (string_of_expr ft)))

  | Ann (e, t) ->
    let _ = infer_universe ctx t in
    check ctx e t;
    Normalizer.normalize t

  | Nat ->
    Universe 0

  | Zero ->
    Nat

  | Succ n ->
    check ctx n Nat;
    Nat

  | Vec (a, n) ->
    check ctx a (Universe 0);
    check ctx n Nat;
    Universe 0

  | Nil ->
    type_error
      "Cannot infer the element type of Nil.\n\
       Hint: wrap it in a type annotation, e.g. (Nil : Vec A Zero)"

  | Cons (h, t) ->
    let a = infer ctx h in
    let tt = infer ctx t in
    (match Normalizer.normalize tt with
     | Vec (a', n) ->
       if not (Equal.equal a a') then
         type_error (Printf.sprintf
           "Cons: head has type %s but tail has element type %s"
           (string_of_expr a) (string_of_expr a'));
       Vec (a, Succ n)
     | _ ->
       type_error (Printf.sprintf
         "Cons: tail must be a Vec, but got type %s"
         (string_of_expr tt)))

  | Mat (m, n) ->
    check ctx m Nat;
    check ctx n Nat;
    Universe 0

  | Fin n ->
    check ctx n Nat;
    Universe 0

(** Verifies that [e] has type [expected] in context [ctx]. *)
and check (ctx : context) (e : expr) (expected : expr) : unit =
  match e, Normalizer.normalize expected with
  | Lambda (x, ann, body), Pi (y, s, t) ->
    if not (Equal.equal ann s) then
      type_error (Printf.sprintf
        "Lambda annotation %s does not match expected domain %s"
        (string_of_expr ann) (string_of_expr s));
    let t' = Subst.subst y (Var x) t in
    check (extend ctx x s) body t'
  | _ ->
    let inferred = infer ctx e in
    if not (Equal.equal inferred expected) then
      type_error (Printf.sprintf
        "Expected type %s\n  but got type %s\n  for expression %s"
        (string_of_expr expected)
        (string_of_expr inferred)
        (string_of_expr e))

(** Infers the type of [t], ensures it is a universe, and returns its level. *)
and infer_universe (ctx : context) (t : expr) : int =
  let u = infer ctx t in
  match Normalizer.normalize u with
  | Universe k -> k
  | _ ->
    type_error (Printf.sprintf
      "Expected a type (universe), but %s has type %s"
      (string_of_expr t) (string_of_expr u))

end
