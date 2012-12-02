open Protocol_types 
open Protocol_clientKernel

let key = 'H'

let send kernel ~version = 
  enqueue kernel 
    ~send:begin fun w -> 
      w # char key ;
      w # int version 
    end
    ~recv:begin fun r -> 
      r # int 
    end
    
module Server = struct

  let handle ~version s wf = 
    Log.(out AUDIT "Handshake : client version %d" version) ;
    wf (fun w -> w # int version) 
      
  let parse r = 
    handle ~version:(r # int) 
      
end

let endpoint = key, Server.parse
