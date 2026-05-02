(** Type equality via normalization. *)

open Ast

(** Check equality up to normalization and alpha-equivalence. *)
let equal (e1 : expr) (e2 : expr) : bool =
  let e1 = Normalizer.normalize e1 in
  let e2 = Normalizer.normalize e2 in
  let rec eq e1 e2 =
    match e1, e2 with
    | Var x, Var y -> x = y
    | Universe k1, Universe k2 -> k1 = k2
    | Nat, Nat -> true
    | Zero, Zero -> true
    | Nil, Nil -> true

    | Succ n1, Succ n2 -> eq n1 n2
    | Fin n1, Fin n2 -> eq n1 n2

    | App (f1, a1), App (f2, a2) ->
      eq f1 f2 && eq a1 a2

    | Ann (e1, t1), Ann (e2, t2) ->
      eq e1 e2 && eq t1 t2

    | Vec (a1, n1), Vec (a2, n2) ->
      eq a1 a2 && eq n1 n2

    | Cons (h1, t1), Cons (h2, t2) ->
      eq h1 h2 && eq t1 t2

    | Mat (m1, n1), Mat (m2, n2) ->
      eq m1 m2 && eq n1 n2

    (* Compare binders modulo alpha-equivalence. *)
    | Pi (x, a1, b1), Pi (y, a2, b2) ->
      eq a1 a2 && eq b1 (Subst.subst y (Var x) b2)

    | Lambda (x, t1, body1), Lambda (y, t2, body2) ->
      eq t1 t2 && eq body1 (Subst.subst y (Var x) body2)

    (* Different constructors are never equal. *)
    | _ -> false
  in
  eq e1 e2