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
  let _    = Protocol.(Response.get (CreateStream.send ~name kernel)) in
  let stream = Pointer.Name.hash name in

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
  let block    = 200 in
  let queries  = ref 0 in
  let buffer   = ref [] in
  while not (Queue.is_empty keys) do 
    let key = Queue.pop keys in
    buffer := key :: !buffer ;
    if List.length !buffer = block || Queue.is_empty keys then begin
      let events = List.rev !buffer in      
      let result = Protocol.AddEvent.send ~stream ~events kernel in
      ignore (Protocol.Response.get result) ; 
      incr queries ; 
      buffer := []
    end 
  done ;

  let d = Unix.gettimeofday () -. start3_t in
  Printf.printf "AddEvent : %fs (%fs/query)\n" d (d /. float_of_int (!queries)) ;   
  (*
  (* Read back the responses *)
  let start4_t = Unix.gettimeofday () in
  while not (Queue.is_empty backqueue) do 
    let _ = Protocol.Response.get (Queue.pop backqueue) in
    ()
  done ;

  Printf.printf "Confirm : %fs\n" (Unix.gettimeofday () -. start4_t);   
  *)
  Protocol.ClientKernel.destroy kernel ;

  let end_t = Unix.gettimeofday () in
  let delta = end_t -. start_t in

  Printf.printf "Time : %fs, Read : %f KB/s, Write : %f KB/s\n"
    delta 
    (float_of_int (pipe # read # count) /. 1024. /. delta) 
    (float_of_int (pipe # write # count) /. 1024. /. delta) 
    


let () = connect ~port:4567

