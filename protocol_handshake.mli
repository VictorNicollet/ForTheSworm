val endpoint : Protocol_types.endpoint
  
val send : version:int -> SocketStream.write -> unit
val recv : SocketStream.read -> int

