open Store
open Encode7bit
open Pointer

let store = "store"
let blobStore = Blob.Store.define store
let ptrStore  = Pointer.Store.define store

let empty  = Blob.hash (Blob.make "") 

let server = object (server)

  method save_blob data = 
    let key = Blob.hash data in 
    Log.(out AUDIT "SaveBlob : %s (%d bytes)" (Key.to_hex_short key) (Blob.bytes data)) ;   
    if key = empty then empty else 
      Blob.Store.save blobStore data

  method load_blob key = 
    Log.(out AUDIT "LoadBlob : %s" (Key.to_hex_short key)) ;
    if key = empty then Some (Blob.make "") else 
      try Blob.Store.load blobStore key 
      with exn -> 
	Log.(out ERROR "Load blob %s failed : %S" 
	       (Key.to_hex_short key)
	       (Printexc.to_string exn)) ;
	None
	  
  method add_events key events = 
    List.iter (fun event -> 
      Log.(out AUDIT "AddEvent : %s <- %s" (Key.to_hex_short key) (Key.to_hex_short event))
    ) events ;   
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
