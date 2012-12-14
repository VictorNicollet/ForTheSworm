type server = <
  save : Blob.t -> Key.t ;
  load : Key.t -> Blob.t option 
>

type responder = Pipe.write -> unit

type request = Pipe.read -> server -> (responder -> unit) -> unit

type endpoint = char * request
