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

let () = Listener.start ~port:4567 ~max:10 (fun _ read write -> 
  let rec loop () = 
    let request = Protocol.parseNextRequest read in
    request server write ;
    loop ()
  in
  try loop () with SocketStream.EOT -> 
    Log.(out AUDIT "Sent : %.3f KB, Received : %.3f KB"
      (float_of_int (write # count) /. 1024.) 
      (float_of_int (read  # count) /. 1024.)) 
) 
