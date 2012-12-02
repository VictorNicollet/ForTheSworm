open Store
open Encode7bit
open SocketStream

let store = "store"

let server = object

  method save data = 
    let key = Key.of_sha1 (Sha1.string data) in 
    Store.save store key data ;
    key 

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
