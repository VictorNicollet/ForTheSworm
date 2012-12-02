open Encode7bit

let data = Array.init 1000 (fun i ->
  String.create 4088 ^ Printf.sprintf "%04d" i ^ Printf.sprintf "%04x" (Unix.getpid ()) 
) 

let connect ~port = 
  let sock = Unix.(socket PF_INET SOCK_STREAM 0) in
  Unix.(connect sock (ADDR_INET (inet_addr_loopback,port))) ;
  let read = new SocketStream.read sock in
  let write = new SocketStream.write sock in

  let start_t = Unix.gettimeofday () in

  (* Shake hands *)
  Protocol.Handshake.send ~version:Protocol.version write ;
  let version = Protocol.Handshake.recv read in
  Printf.printf "Version: %d\n" version ; 

  (* Upload some data *)
  for i = 1 to 1000 do 
    Protocol.Save.send ~data:data.(i-1) write ;
    let id = Protocol.Save.recv read in
    () 
    (* Printf.printf "Saved #%d : %s" i (Key.to_hex_short id) ; *)
    (* print_newline () *)
  done ;

  let end_t = Unix.gettimeofday () in
  let delta = end_t -. start_t in

  Printf.printf "Time : %fs, Read : %f KB/s, Write : %f KB/s\n"
    delta 
    (float_of_int (read # count) /. 1024. /. delta) 
    (float_of_int (write # count) /. 1024. /. delta) ;
    
  Unix.(shutdown sock SHUTDOWN_ALL) 

let () = connect ~port:4567

