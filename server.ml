open Store
open Encode7bit
open SocketStream

let () = Listener.start ~port:4567 ~max:10 (fun _ _ _ -> ()) 
