OCAMLC = ocamlc
OCAMLYACC = ocamlyacc
OCAMLLEX = ocamllex

SOURCES = typecheck/ast.ml typecheck/subst.ml typecheck/normalizer.ml \
          typecheck/equal.ml typecheck/context.ml typecheck/typecheck.ml \
          typecheck/parser.mli typecheck/parser.ml typecheck/lexer.ml \
          typecheck/main.ml

typechecker: typecheck/parser.ml typecheck/lexer.ml
	$(OCAMLC) -I typecheck $(SOURCES) -o typechecker

typecheck/parser.ml typecheck/parser.mli: typecheck/parser.mly
	$(OCAMLYACC) typecheck/parser.mly

typecheck/lexer.ml: typecheck/lexer.mll
	$(OCAMLLEX) typecheck/lexer.mll

run: typechecker
	./typechecker examples

clean:
	rm -f typechecker typecheck/*.cmi typecheck/*.cmo typecheck/*.cmx typecheck/*.o
	rm -f typecheck/parser.ml typecheck/parser.mli typecheck/lexer.ml

.PHONY: run clean
