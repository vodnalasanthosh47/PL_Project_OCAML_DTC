# Dependent Type Checker in OCaml

> A minimal, academically rigorous implementation of a **bidirectional dependent type checker** based on Martin-Löf Type Theory, written in OCaml.

---

## Overview

This project implements a core **dependent type theory** — a formal system where types can *depend on values* — from scratch in OCaml. It serves as a proof-of-concept for how a language runtime can statically enforce rich invariants like "this list has exactly *n* elements" or "this index is always in bounds", eliminating entire classes of runtime errors at compile time.

The checker uses a classic **bidirectional type checking** algorithm, which separates type inference (synthesizing a type from an expression) from type checking (verifying an expression against a known type). Definitional equality is decided by reducing terms to **beta-normal form** via capture-avoiding substitution.

---

## Theoretical Background

### Dependent Types in a Nutshell

In ordinary type systems (e.g., Java, Haskell), types and terms occupy separate universes. In a dependent type theory, types are **first-class values**: a type can mention a term. The canonical example is the *length-indexed vector*:

```
Vec A n   -- a list of exactly n elements of type A
```

Here `n` is a term of type `Nat` appearing inside a type. This makes the following statically safe:

- **`head`** — can only be called on `Vec A (Succ n)`, not `Vec A Zero`. The empty-list crash is a type error.
- **`index`** — the index argument has type `Fin n` (a number strictly less than `n`), making out-of-bounds access a type error.

### Universe Hierarchy

To avoid Girard's paradox (the type-theoretic analogue of Russell's paradox), types live in an infinite hierarchy of *universes*:

```
Type0 : Type1 : Type2 : ...
```

`Nat`, `Vec A n`, and other concrete types live in `Type0`. The type `Type0` itself lives in `Type1`, and so on.

### Bidirectional Type Checking

The algorithm has two mutually recursive modes:

| Mode | Signature | Description |
|------|-----------|-------------|
| **Infer** | `infer ctx e → type` | Synthesizes the type of `e` from scratch |
| **Check** | `check ctx e expected → unit` | Verifies `e` has a given expected type |

Lambdas cannot be inferred in isolation (their argument type is unknown), so they must either be **checked** against a Pi-type or **annotated** explicitly with `(e : T)`. All other constructs (`App`, `Pi`, `Var`, builtins) can be inferred.

### Capture-Avoiding Substitution

When beta-reducing `(λx. body) arg → body[x := arg]`, a naive substitution would capture free variables. This implementation uses **capture-avoiding substitution** with a gensym counter to generate fresh names when a variable in `arg` would be shadowed by a binder in `body`.

### Definitional Equality

Two terms are definitionally equal if they reduce to the same beta-normal form. The `equal` module normalizes both sides independently using the `normalize` function and then compares the resulting normal forms structurally.

---

## Features

| Feature | Syntax | Description |
|---------|--------|-------------|
| Universe Hierarchy | `Type0`, `Type1`, ... | Stratified types to avoid paradox |
| Dependent Product | `Pi(x : A). B` | `x` may appear free in `B` |
| Lambda Abstraction | `Lambda(x : A). body` | Explicitly annotated argument |
| Application | `f arg` | Standard function application |
| Type Annotation | `(e : T)` | Switches from check to infer mode |
| Natural Numbers | `Nat`, `Zero`, `Succ n` | Peano-encoded naturals |
| Length-Indexed Vectors | `Vec A n`, `Nil`, `Cons h t` | Statically-sized lists |
| Bounded Naturals | `Fin n` | Index type for safe array access |
| Matrices | `Mat m n` | Typed `m × n` matrix |
| Bidirectional Checking | `infer` / `check` mode | Minimizes annotation burden |
| Beta Normalization | Automatic | Used for equality and type comparison |
| Capture-Avoiding Subst | Automatic | Gensym-based fresh name generation |
| Definitional Equality | `equal lhs = rhs` | Decides equality up to beta-reduction |

---

## Project Structure

```
.
├── Makefile                      # Build rules
├── main.ml                       # Top-level entry point and script interpreter
├── examples/                     # Test scripts
│   ├── 01_vec_head_type.txt      # Vec head function type
│   ├── 02_vec_head_empty.txt     # Rejection: head of empty Vec
│   ├── 03_vec_append_type.txt    # Vec append function type
│   ├── 04a_mat_mul_type.txt      # Matrix multiplication type
│   ├── 04b_mat_mul_mismatch.txt  # Rejection: mismatched matrix dimensions
│   ├── 05_safe_index_fin.txt     # Safe array indexing via Fin
│   └── 06_normalization.txt      # Definitional equality via beta reduction
└── typecheck/
    ├── ast.ml                    # Core expression type (AST)
    ├── context.ml                # Typing context (variable → type map)
    ├── subst.ml                  # Capture-avoiding substitution + free vars
    ├── normalizer.ml             # Beta-reduction to normal form
    ├── equal.ml                  # Definitional equality (normalize + compare)
    ├── typecheck.ml              # Bidirectional infer/check algorithm
    ├── lexer.mll                 # ocamllex lexer
    ├── parser.mly                # ocamlyacc grammar
    └── main.ml                   # Parser-driven test harness
```

### Module Dependency Graph

```
ast.ml
  └── context.ml
  └── subst.ml
       └── normalizer.ml
            └── equal.ml
                 └── typecheck.ml
                      └── main.ml  (parser + runner)
```

---

## Build & Run

### Prerequisites

- [OCaml](https://ocaml.org/install) (any recent version)
- `ocamllex` and `ocamlyacc` (bundled with OCaml)
- GNU Make

### Compile

```bash
make typechecker
```

This runs `ocamllex` and `ocamlyacc` to generate the lexer/parser, then compiles all modules in dependency order with `ocamlc`.

### Run All Examples

```bash
make run
# equivalent to: ./typechecker examples
```

### Clean Build Artifacts

```bash
make clean
```

---

## Script Syntax

The type checker reads plain-text scripts from the `examples/` directory. Each non-empty line is one of three commands:

### `assume x : T`

Introduces a variable `x` with type `T` into the global context. Useful for axiomatizing external types or functions.

```
assume A : Type0
assume n : Nat
assume head : Pi(A : Type0). Pi(n : Nat). Pi(_ : Vec A (Succ n)). A
```

### `infer e`

Asks the type checker to synthesize and print the type of expression `e`. Prints `ACCEPT` with the inferred type, or `REJECT` with an error message.

```
infer Pi(A : Type0). Pi(n : Nat). Pi(_ : Vec A (Succ n)). A
```

### `equal lhs = rhs`

Checks if two expressions are **definitionally equal** by normalizing both and comparing their normal forms.

```
equal Vec Nat (Succ (Succ Zero)) = Vec Nat (App (Lambda(n : Nat). Succ (Succ n)) Zero)
```

---

## Example Scripts

### `01_vec_head_type.txt` — Inferring a Vec Head Signature

```
infer Pi(A : Type0). Pi(n : Nat). Pi(_ : Vec A (Succ n)). A
```

Infers the type of the *head* function. Taking a vector of length at least 1 (`Succ n`) guarantees it is non-empty, so returning the head element `A` is always safe. The type checker verifies this entire Pi-type is well-formed and lives in `Type0`.

---

### `02_vec_head_empty.txt` — Rejecting Head on Empty Vec

Sets up a `head` function and attempts to call it on `Nil`. The type checker **rejects** this because `Nil : Vec A Zero` but `head` demands `Vec A (Succ n)`, and `Zero ≢ Succ n` definitionally.

---

### `04b_mat_mul_mismatch.txt` — Catching a Matrix Dimension Error

```
assume mul : Pi(i : Nat). Pi(j : Nat). Pi(k : Nat). Pi(_ : Mat i j). Pi(_ : Mat j k). Mat i k
assume mat_3_4 : Mat (Succ(Succ(Succ Zero))) (Succ(Succ(Succ(Succ Zero))))   -- 3×4
assume mat_5_6 : Mat (Succ(...5...)) (Succ(...6...))                          -- 5×6
infer mul 3 4 6 mat_3_4 mat_5_6   -- ERROR: inner dimensions 4 ≠ 5
```

The type checker catches the dimension mismatch (`4 ≠ 5`) and **rejects** the program — exactly the kind of silent crash that would occur at runtime in a conventional language.

---

### `05_safe_index_fin.txt` — Bounds-Safe Indexing via `Fin`

```
infer Pi(A : Type0). Pi(n : Nat). Pi(_ : Vec A n). Pi(_ : Fin n). A
```

The `Fin n` type encodes all natural numbers strictly less than `n`. An index of type `Fin n` into a `Vec A n` is therefore always in-bounds by construction — the type system makes out-of-bounds access impossible to express.

---

### `06_normalization.txt` — Definitional Equality via Beta Reduction

```
equal Vec Nat (Succ (Succ Zero)) = Vec Nat (App (Lambda(n : Nat). Succ (Succ n)) Zero)
```

The right-hand side beta-reduces: `(λn. Succ (Succ n)) Zero ↝ Succ (Succ Zero)`. Both sides normalize to `Vec Nat (Succ (Succ Zero))`, so the checker reports `EQUAL`. This demonstrates that type checking is performed *up to computation*.

---

## Implementation Notes

### Why `check` returns `unit`

The `check` function returns `unit` rather than a type because its job is purely *verification*. The expected type is already known by the caller; `check` only needs to confirm or refute it. Returning a value would be redundant.

### Why Substitution-Based (Not Closure-Based) Evaluation

The normalizer uses **explicit capture-avoiding substitution** rather than an environment/closure model. This is a deliberate choice: the AST is the single source of truth, and beta-normal forms are just AST values. This simplifies definitional equality (structural comparison of two ASTs) and is the standard approach in pen-and-paper presentations of Martin-Löf Type Theory.

### Bare Lambdas Cannot Be Inferred

```
-- ERROR: cannot infer type of a bare lambda
infer Lambda(x : Nat). Succ x

-- OK: supply a type annotation to switch to check mode
infer (Lambda(x : Nat). Succ x : Pi(_ : Nat). Nat)
```

This is a fundamental property of bidirectional type checking. The argument type of a lambda is only known when *checked* against a Pi-type; the `Ann` construct (`e : T`) bridges the two modes.

---

## References

- Andrej Bauer, [*How to Implement Dependent Type Theory*](https://math.andrej.com/2012/11/08/how-to-implement-dependent-type-theory-i/) — primary algorithmic reference.
- Per Martin-Löf, *Intuitionistic Type Theory* (1984).
- Ulf Norell, *Towards a Practical Programming Language Based on Dependent Type Theory* (2007).
- The [Agda proof assistant](https://wiki.portal.chalmers.se/agda/) — conceptual inspiration for the type structure.
