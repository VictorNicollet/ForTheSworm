open Protocol_types 
open Protocol_clientKernel

let keyword = 'b'

let send kernel ~key = 
  enqueue kernel 
    ~send:begin fun w -> 
      w # char   keyword  ;
      w # key    key  ;
    end
    ~recv:begin fun r -> 
      let i = r # int in 
      if i = 0 then None else 
	Some (Blob.of_bytes (r # string (i - 1))) 
    end
    
module Server = struct

  let handle ~key s wf = 
    ignore (Thread.create begin fun key -> 
      match s # load_blob key with
      | None      -> wf (fun w -> w # int 0)
      | Some data -> let l = Blob.bytes data in 
		     let b = Blob.to_bytes data in
		     wf (fun w -> w # int (l + 1) ; w # string b) 
    end key) 
      
  let parse r =
    let key = r # key in
    handle ~key
      
end

let endpoint = keyword, Server.parse
