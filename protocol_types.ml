type server = <
  name : string ;
>

type request = server -> SocketStream.write -> unit

type endpoint = char * (SocketStream.read -> request)
