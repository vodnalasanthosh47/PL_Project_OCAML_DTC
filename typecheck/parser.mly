%{
open Ast
%}

%token LPAREN RPAREN DOT COLON
%token PI LAMBDA APP ANN
%token VEC MAT CONS FIN SUCC
%token NAT ZERO NIL
%token <int> TYPE
%token <string> IDENT
%token EOF

%start main
%type <Ast.expr> main

%%

main:
  | expr EOF                                          { $1 }
;

expr:
  | PI LPAREN IDENT COLON expr RPAREN DOT expr        { Pi($3, $5, $8) }
  | LAMBDA LPAREN IDENT COLON expr RPAREN DOT expr    { Lambda($3, $5, $8) }
  | APP atom atom                                      { App($2, $3) }
  | ANN atom atom                                      { Ann($2, $3) }
  | VEC atom atom                                      { Vec($2, $3) }
  | MAT atom atom                                      { Mat($2, $3) }
  | CONS atom atom                                     { Cons($2, $3) }
  | FIN atom                                           { Fin($2) }
  | SUCC atom                                          { Succ($2) }
  | atom                                               { $1 }
;

atom:
  | LPAREN expr RPAREN                                 { $2 }
  | NAT                                                { Nat }
  | ZERO                                               { Zero }
  | NIL                                                { Nil }
  | TYPE                                               { Universe($1) }
  | IDENT                                              { Var($1) }
;
