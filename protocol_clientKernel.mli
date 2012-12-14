type t 

val make : Pipe.readwrite -> t

val enqueue :
     t
  -> send:(Pipe.write -> unit)
  -> recv:(Pipe.read -> 'a)
  -> 'a Protocol_response.t

val destroy : t -> unit
