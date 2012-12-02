open Protocol_types 
open Protocol_clientKernel

let key = '<'

let send kernel ~data = 
  enqueue kernel 
    ~send:begin fun w -> 
      let id  = Key.of_sha1 (Sha1.string data) in
      let len = String.length data in
      w # char   key  ;
      w # key    id   ;
      w # int    len  ;
      w # string data
    end
    ~recv:begin fun r -> 
      r # key 
    end
    
module Server = struct

  let handle ~id ~data ~length s wf = 
    Log.(out AUDIT "Save : %s (%d bytes)" (Key.to_hex_short id) length) ;   
    ignore (Thread.create begin fun data -> 
      let key = s # save data in
      wf (fun w -> w # key key) 
    end data) 
      
  let parse r =
    let id     = r # key in
    let length = r # int in
    let data   = r # string length in
    handle ~id ~length ~data
      
end

let endpoint = key, Server.parse
