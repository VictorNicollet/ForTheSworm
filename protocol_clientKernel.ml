module Response = Protocol_response

type t = {
  pipe    :  Pipe.readwrite ;
  pending : (Pipe.read option -> unit) PendArray.t ;
}

let make pipe = {
  pipe ;
  pending = PendArray.make () 
}

let attempt t () = 
  let read = t.pipe # read in 
  (* TODO : poll for values instead of blocking *)
  let i = read # int in 
  match PendArray.remove t.pending i with 
    | None -> () 
    | Some reader -> reader (Some read)
  
let enqueue t ~send ~recv = 
  let response = Response.make (attempt t) in
  let i = PendArray.add t.pending begin fun read -> 
    let result =
      match read with None -> BatStd.Bad Pipe.EOT | Some read -> 
	try BatStd.Ok (recv read) with exn -> BatStd.Bad exn 
    in 
    Response.set response result
  end in 
  t.pipe # write # int i ;
  send (t.pipe # write) ;
  response
  
let destroy t =
  PendArray.clear t.pending (fun f -> f None) 
