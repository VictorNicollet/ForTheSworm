open Encode7bit
open PendArray

let data = Array.init 1000 (fun i ->
  String.create 4088 ^ Printf.sprintf "%04d" i ^ Printf.sprintf "%04x" (Unix.getpid ()) 
) 

let connect ~port = 
  let sock = Unix.(socket PF_INET SOCK_STREAM 0) in
  Unix.(connect sock (ADDR_INET (inet_addr_loopback,port))) ;

  let stream = new SocketStream.stream sock in 
  let kernel = Protocol.ClientKernel.make stream in 

  let start_t = Unix.gettimeofday () in

  (* Shake hands *)
  let result = Protocol.Handshake.send ~version:Protocol.version kernel in
  let version = Protocol.Response.get result in
  Printf.printf "Version: %d\n" version ; 

  (* Upload some data *)
  for i = 1 to 1000 do 
    ignore (Protocol.Save.send ~data:data.(i-1) kernel)
  done ;
  
  Protocol.ClientKernel.destroy kernel ;

  let end_t = Unix.gettimeofday () in
  let delta = end_t -. start_t in

  Printf.printf "Time : %fs, Read : %f KB/s, Write : %f KB/s\n"
    delta 
    (float_of_int (stream # read # count) /. 1024. /. delta) 
    (float_of_int (stream # write # count) /. 1024. /. delta) ;
    
  Unix.(shutdown sock SHUTDOWN_ALL) 

let () = connect ~port:4567

