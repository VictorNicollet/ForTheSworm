open Protocol_types 
open Protocol_clientKernel

let keyword = '+'

let send kernel ~stream ~events = 
  enqueue kernel 
    ~send:begin fun w ->
      w # char keyword ; 
      w # key stream ; 
      w # int (List.length events) ;
      List.iter (w # key) events ;
    end
    ~recv:begin fun r -> 
      match r # int with 
	| 0 -> None
	| n -> Some (n-1) 
    end
    
module Server = struct

  let handle ~stream ~events s wf =
    List.iter (fun event -> 
      Log.(out AUDIT "AddEvent : %s <- %s" (Key.to_hex_short stream) (Key.to_hex_short event))
    ) events ;   
    ignore (Thread.create begin fun (stream,events) ->  
      let version = s # add_events stream events in
      wf (fun w -> match version with 
	| None   -> w # int 0
	| Some v -> w # int (v + 1))
    end (stream,events)) 
      
  let parse r =
    let stream = r # key in
    let rec events acc n = 
      if n = 0 then List.rev acc else 
	events (r # key :: acc) (n - 1) 
    in
    let events = events [] (r # int) in
    handle ~stream ~events
      
end

let endpoint = keyword, Server.parse
