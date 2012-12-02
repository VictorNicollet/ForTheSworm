type server = <
  save : string -> Key.t ;
>

type responder = SocketStream.write -> unit

type request = SocketStream.read -> server -> (responder -> unit) -> unit

type endpoint = char * request
