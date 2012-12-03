all: 
	ocamlbuild -use-ocamlfind server.byte
	ocamlbuild -use-ocamlfind client.byte