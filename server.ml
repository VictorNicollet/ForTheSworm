open Store
open Encode7bit
open SocketStream
open Pointer

let store = "store"

let server = object

  method save data = 
    BlobStore.save store data

  method load key = 
    try BlobStore.load store key 
    with exn -> 
      Log.(out ERROR "Load %s failed : %S" 
	     (Key.to_hex_short key)
	     (Printexc.to_string exn)) ;
      None

end

let () = Listener.start ~port:4567 ~max:10 (fun _ stream -> 
  let rec loop () = 
    Protocol.parseNextRequest stream server ;
    if stream # write # closed then raise SocketStream.EOT ;
    loop ()
  in
    try loop () with SocketStream.EOT -> 
    Log.(out AUDIT "Sent : %.3f KB, Received : %.3f KB"
      (float_of_int (stream # write # count) /. 1024.) 
      (float_of_int (stream # read  # count) /. 1024.)) 
) 
