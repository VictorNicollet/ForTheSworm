open Protocol_types 
open Protocol_clientKernel

let keyword = '?'

let send kernel ~stream ~start ~count =
  enqueue kernel 
    ~send:begin fun w ->
      w # char keyword ; 
      w # key stream ; 
      w # int start ;
      w # int count ;
    end
    ~recv:begin fun r -> 
      match r # int with 
	| 0 -> None
	| n -> Some begin
	  let rec read acc n = 
	    if n = 0 then List.rev acc else 
	      read (r # key :: acc) (n - 1) 
	  in
	  read [] (n-1) 
	end
    end
    
module Server = struct

  let handle ~stream ~start ~count s wf =
    ignore (Thread.create begin fun (stream,start,count) ->  
      let events = s # get_events stream start count in
      wf (fun w -> match events with 
	| None   -> w # int 0
	| Some e -> let l = List.length e in
		    w # int (l + 1) ;
		    List.iter (w # key) e)
    end (stream,start,count)) 
      
  let parse r =
    let stream = r # key in
    let start  = r # int in 
    let count  = r # int in 
    handle ~stream ~start ~count
      
end

let endpoint = keyword, Server.parse
