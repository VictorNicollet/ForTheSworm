open Protocol_types 
open Protocol_clientKernel

let keyword = 'S'

let send kernel ~name = 
  enqueue kernel 
    ~send:begin fun w -> 
      w # char keyword ; 
      let bytes = Pointer.Name.to_bytes name in
      w # int (String.length bytes) ; 
      w # string bytes ;
    end
    ~recv:begin fun r -> 
      let i = r # int in 
      if i = 0 then None else 
	Some (r # key) 
    end
    
module Server = struct

  let handle ~name s wf = 
    ignore (Thread.create begin fun name -> 
      match s # new_stream name with
	| None     -> wf (fun w -> w # int 0)
	| Some key -> wf (fun w -> w # int 1 ; w # key key) 
    end name) 
      
  let parse r =
    let l     = r # int in 
    let bytes = r # string l in
    let name  = Pointer.Name.of_bytes bytes in  
    handle ~name
      
end

let endpoint = keyword, Server.parse
