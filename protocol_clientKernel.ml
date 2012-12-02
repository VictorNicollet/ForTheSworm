module Response = Protocol_response

type t = {
  stream  : SocketStream.stream ;
  pending : (SocketStream.read option -> unit) PendArray.t ;
}

let make stream = {
  stream ;
  pending = PendArray.make () 
}

let attempt t () = 
  let read = t.stream # read in 
  (* TODO : poll for values instead of blocking *)
  let i = read # int in 
  match PendArray.remove t.pending i with 
    | None -> () 
    | Some reader -> reader (Some read)
  
let enqueue t ~send ~recv = 
  let response = Response.make (attempt t) in
  let i = PendArray.add t.pending begin fun read -> 
    let result =
      match read with None -> BatStd.Bad SocketStream.EOT | Some read -> 
	try BatStd.Ok (recv read) with exn -> BatStd.Bad exn 
    in 
    Response.set response result
  end in 
  t.stream # write # int i ;
  send (t.stream # write) ;
  response
  
let destroy t =
  PendArray.clear t.pending (fun f -> f None) 
