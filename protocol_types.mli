type server = <
  save : Blob.t -> Key.t ;
  load : Key.t  -> Blob.t option 
>

type responder = SocketStream.write -> unit

type request = SocketStream.read -> server -> (responder -> unit) -> unit

type endpoint = char * request
