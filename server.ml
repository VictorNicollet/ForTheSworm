open Store
open Encode7bit
open Pointer

let store = "store"
let blobStore = Blob.Store.define store
let ptrStore  = Pointer.Store.define store

let server = object (server)

  method save_blob data = 
    if Blob.hash data = Key.empty then Key.empty else 
      Blob.Store.save blobStore data

  method load_blob key = 
    if key = Key.empty then Some (Blob.make "") else 
      try Blob.Store.load blobStore key 
      with exn -> 
	Log.(out ERROR "Load blob %s failed : %S" 
	       (Key.to_hex_short key)
	       (Printexc.to_string exn)) ;
	None
	  
  method add_events key events = 
    match Pointer.Store.Stream.add ptrStore server key events with 
      | `OK version -> Some version
      | `MISSING -> None

  method new_stream name = 
    Log.(out AUDIT "CreateStream : %s = %s" 
	   (Key.to_hex_short (Pointer.Name.hash name)) (Pointer.Name.human_readable name) );
    Pointer.Store.Stream.create ptrStore server ~name

  method del_stream key = 
    Pointer.Store.Stream.delete ptrStore key 

end

let handler iaddr pipe = 

  let rec loop () = 
    Protocol.parseNextRequest pipe server ;
    if pipe # write # closed then raise Pipe.EOT ;
    loop ()
  in

  try loop () with Pipe.EOT -> 
    Log.(out AUDIT "Sent : %.3f KB, Received : %.3f KB"
	   (float_of_int (pipe # write # count) /. 1024.) 
	   (float_of_int (pipe # read  # count) /. 1024.)) 
      
let () = 
  Listener.start ~port:4567 ~max:10 ~handler
