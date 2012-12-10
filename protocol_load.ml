open Protocol_types 
open Protocol_clientKernel

let keyword = '>'

let send kernel ~key = 
  enqueue kernel 
    ~send:begin fun w -> 
      w # char   keyword  ;
      w # key    key  ;
    end
    ~recv:begin fun r -> 
      let i = r # int in 
      if i = 0 then None else 
	Some (r # string (i - 1)) 
    end
    
module Server = struct

  let handle ~key s wf = 
    Log.(out AUDIT "Load : %s" (Key.to_hex_short key)) ;   
    ignore (Thread.create begin fun key -> 
      match s # load key with
      | None      -> wf (fun w -> w # int 0)
      | Some data -> let l = String.length data in
		     wf (fun w -> w # int (l + 1) ; w # string data) 
    end key) 
      
  let parse r =
    let key = r # key in
    handle ~key
      
end

let endpoint = keyword, Server.parse
