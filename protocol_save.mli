val endpoint : Protocol_types.endpoint
  
val send : data:string -> SocketStream.write -> unit
val recv : SocketStream.read -> Key.t

