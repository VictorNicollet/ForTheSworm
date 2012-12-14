open Protocol_types 
open Protocol_clientKernel

let key = '<'

let send kernel ~blob = 
  enqueue kernel 
    ~send:begin fun w -> 
      let id  = Blob.hash  blob in
      let len = Blob.bytes blob in
      w # char   key  ;
      w # key    id   ;
      w # int    len  ;
      w # string (Blob.to_bytes blob)
    end
    ~recv:begin fun r -> 
      r # key 
    end
    
module Server = struct

  let handle ~id ~data ~length s wf = 
    Log.(out AUDIT "Save : %s (%d bytes)" (Key.to_hex_short id) length) ;   
    ignore (Thread.create begin fun data -> 
      let key = s # save_blob (Blob.of_bytes data) in
      wf (fun w -> w # key key) 
    end data) 
      
  let parse r =
    let id     = r # key in
    let length = r # int in
    let data   = r # string length in
    handle ~id ~length ~data
      
end

let endpoint = key, Server.parse
