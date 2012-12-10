type server = <
  save : string -> Key.t ;
  load : Key.t  -> string option 
>

type responder = SocketStream.write -> unit

type request = SocketStream.read -> server -> (responder -> unit) -> unit

type endpoint = char * request
