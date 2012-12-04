open Protocol_types 

let key = 'H'

let send ~version w = 
  w # char key ;
  w # int version 
    
let recv r = 
  r # int 
    
module Server = struct

  let handle ~version s w = 
    Log.(out AUDIT "Handshake : client version %d" version) ;
    w # int version 
      
  let parse r = 
    handle ~version:(r # int) 
      
end

let endpoint = key, Server.parse
