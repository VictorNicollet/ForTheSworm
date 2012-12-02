open Protocol_types 

let key = '<'

let send ~data w =
  let id  = Key.of_sha1 (Sha1.string data) in
  let len = String.length data in
  w # char   key  ;
  w # key    id   ;
  w # int    len  ;
  w # string data

let recv r = 
  r # key 
    
module Server = struct

  let handle ~id ~data ~length s w = 
    Log.(out AUDIT "Save : %s (%d bytes)" (Key.to_hex_short id) length) ;
    w # key id
      
  let parse r =
    let id     = r # key in
    Log.(out DEBUG "Save: id = %s" (Key.to_hex id)) ;
    let length = r # int in
    Log.(out DEBUG "Save: size = %d" length) ;
    let data   = r # string length in
    handle ~id ~length ~data
      
end

let endpoint = key, Server.parse
