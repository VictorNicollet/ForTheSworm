all: 
	ocamlbuild -use-ocamlfind server.byte
	ocamlbuild -use-ocamlfind client.byte

run: 
	ocamlbuild -use-ocamlfind server.byte
	killall server.byte || echo 'None running !'
	./server.byte & 
	ocamlbuild -use-ocamlfind client.byte
