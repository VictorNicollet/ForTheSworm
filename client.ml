open Encode7bit
open PendArray

let data = Array.init 1000 (fun i ->
  String.create 4088 ^ Printf.sprintf "%04d" i ^ Printf.sprintf "%04x" (Unix.getpid ()) 
) 

let connect ~port = 
  let sock = Unix.(socket PF_INET SOCK_STREAM 0) in
  Unix.(connect sock (ADDR_INET (inet_addr_loopback,port))) ;

  let pipe   = new Pipe.readwrite sock in 
  let kernel = Protocol.ClientKernel.make pipe in 

  (* Shake hands *)
  let result = Protocol.Handshake.send ~version:Protocol.version kernel in
  let version = Protocol.Response.get result in
  Printf.printf "Version: %d\n" version ; 

  (* Upload some data *)
  let start_t = Unix.gettimeofday () in
  let writequeue = Queue.create () in
  for i = 1 to 1000 do 
    let blob = Blob.make data.(i-1) in
    Queue.push (Protocol.SaveBlob.send ~blob kernel) writequeue
  done ;

  Printf.printf "Write : %fs\n" (Unix.gettimeofday () -. start_t) ;

  (* Read back the written data *)
  let start2_t = Unix.gettimeofday () in
  let readqueue = Queue.create () in
  while not (Queue.is_empty writequeue) do 
    let key = Protocol.Response.get (Queue.pop writequeue) in
    Queue.push (Protocol.LoadBlob.send ~key kernel) readqueue
  done ;

  let i = ref 0 in
  let e = ref 0 in
  while not (Queue.is_empty readqueue) do
    let read = Protocol.Response.get (Queue.pop readqueue) in
    let read = BatOption.map Blob.data read in 
    if read <> Some data.(!i) then incr e ;
    incr i 
  done ;

  Printf.printf "Read : %fs (%d errors)\n" (Unix.gettimeofday () -. start2_t) !e;
  
  Protocol.ClientKernel.destroy kernel ;

  let end_t = Unix.gettimeofday () in
  let delta = end_t -. start_t in

  Printf.printf "Time : %fs, Read : %f KB/s, Write : %f KB/s\n"
    delta 
    (float_of_int (pipe # read # count) /. 1024. /. delta) 
    (float_of_int (pipe # write # count) /. 1024. /. delta) ;
    
  Unix.(shutdown sock SHUTDOWN_ALL) 

let () = connect ~port:4567

