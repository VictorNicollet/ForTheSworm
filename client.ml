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

  (* Create an event stream pointer *)
  let name = Pointer.Name.make [ `S "test" ] in
  let stream = Protocol.(Response.get (CreateStream.send ~name kernel)) in
  let stream = match stream with None -> assert false | Some stream -> stream in 

  Printf.printf "Created Stream %s = %s\n" 
    (Pointer.Name.human_readable name) (Key.to_hex_short stream) ; 

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
  let keys = Queue.create () in
  while not (Queue.is_empty writequeue) do 
    let key = Protocol.Response.get (Queue.pop writequeue) in
    Queue.push key keys ;
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
  
  (* Append all the events to the stream *)
  let start3_t = Unix.gettimeofday () in
  let backqueue = Queue.create () in
  while not (Queue.is_empty keys) do 
    let key = Queue.pop keys in
    Queue.push (Protocol.AddEvent.send ~stream ~events:[key] kernel) backqueue ;    
  done ;

  Printf.printf "AddEvent : %fs\n" (Unix.gettimeofday () -. start3_t);   

  (* Read back the responses *)
  let start4_t = Unix.gettimeofday () in
  while not (Queue.is_empty backqueue) do 
    let _ = Protocol.Response.get (Queue.pop backqueue) in
    ()
  done ;

  Printf.printf "Confirm : %fs\n" (Unix.gettimeofday () -. start4_t);   
  
  Protocol.ClientKernel.destroy kernel ;

  let end_t = Unix.gettimeofday () in
  let delta = end_t -. start_t in

  Printf.printf "Time : %fs, Read : %f KB/s, Write : %f KB/s\n"
    delta 
    (float_of_int (pipe # read # count) /. 1024. /. delta) 
    (float_of_int (pipe # write # count) /. 1024. /. delta) ;
    
  Unix.(shutdown sock SHUTDOWN_ALL) 

let () = connect ~port:4567

