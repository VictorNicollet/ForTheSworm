open Store
open Encode7bit
open Pointer

let store = "store"
let blobStore = Blob.Store.define store

let server = object

  method save_blob data = 
    Blob.Store.save blobStore data

  method load_blob key = 
    try Blob.Store.load blobStore key 
    with exn -> 
      Log.(out ERROR "Load blob %s failed : %S" 
	     (Key.to_hex_short key)
	     (Printexc.to_string exn)) ;
      None

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
