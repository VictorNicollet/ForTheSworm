open Store
open Encode7bit
open SocketStream

let server = object
  method name = "SERVER"
end

let () = Listener.start ~port:4567 ~max:10 (fun _ read write -> 
  let rec loop () = 
    let request = Protocol.parseNextRequest read in
    request server write ;
    loop ()
  in
  try loop () with SocketStream.EOT -> () 
) 
