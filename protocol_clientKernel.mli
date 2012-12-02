type t 

val make : SocketStream.stream -> t

val enqueue :
     t
  -> send:(SocketStream.write -> unit)
  -> recv:(SocketStream.read -> 'a)
  -> 'a Protocol_response.t

val destroy : t -> unit
