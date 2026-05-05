(** context.ml -- Typing contexts as association lists.
    
    A context maps variable names to their types. Extending a context
    with a name that already exists shadows the previous binding. *)

open Ast

(** A context is a list of (name, type) pairs. *)
type context = (string * expr) list

(** The empty context. *)
let empty : context = []

(** [extend ctx x t] returns [ctx] extended with variable [x] of type [t].
    If [x] already exists in [ctx], it is shadowed. *)
let extend (ctx : context) (x : string) (t : expr) : context =
  (x, t) :: ctx

(** [lookup ctx x] returns the type of [x] in [ctx].
    @raise Failure if [x] is not in [ctx]. *)
let lookup (ctx : context) (x : string) : expr =
  match List.assoc_opt x ctx with
  | Some t -> t
  | None -> failwith (Printf.sprintf "Unknown identifier: %s" x)
