all: 
	ocamlbuild -use-ocamlfind server.byte
	ocamlbuild -use-ocamlfind client.byte

run: 
	ocamlbuild -use-ocamlfind server.byte
	killall server.byte || echo 'None running !'
	rm -rf store/*
	echo '' > server.log
	./server.byte & 
	ocamlbuild -use-ocamlfind client.byte
