open Protocol_types 
open Protocol_clientKernel

let key = '+'

let send kernel ~stream ~events = 
  enqueue kernel 
    ~send:begin fun w ->
      w # key stream ; 
      w # int (List.length events) ;
      List.iter (w # key) events ;
    end
    ~recv:begin fun r -> 
      r # int
    end
    
module Server = struct

  let handle ~stream ~events s wf =
    List.iter (fun event -> 
      Log.(out AUDIT "AddEvent : %s <- %s" (Key.to_hex_short stream) (Key.to_hex_short event))
    ) events ;   
    ignore (Thread.create begin fun (stream,events) ->  
      let version = s # add_events stream events in
      wf (fun w -> w # int version) 
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

let endpoint = key, Server.parse
