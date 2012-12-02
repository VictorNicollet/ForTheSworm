open Encode7bit

let connect ~port = 
  let sock = Unix.(socket PF_INET SOCK_STREAM 0) in
  Unix.(connect sock (ADDR_INET (inet_addr_loopback,port))) ;
  let read = new SocketStream.read sock in
  let write = new SocketStream.write sock in

  (* Shake hands *)
  Protocol.Handshake.send ~version:Protocol.version write ;
  let version = Protocol.Handshake.recv read in
  Printf.printf "Version: %d\n" version ; 

  (* Upload some data *)
  Protocol.Save.send ~data:"Hello, world!" write ;
  let id = Protocol.Save.recv read in
  Printf.printf "Saved: %s\n" (Key.to_hex_short id) ;

  Unix.(shutdown sock SHUTDOWN_ALL) 

let () = connect ~port:4567

