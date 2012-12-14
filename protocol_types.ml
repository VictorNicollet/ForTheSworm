type server = <
  save_blob : Blob.t -> Key.t ;
  load_blob : Key.t -> Blob.t option 
>

type responder = Pipe.write -> unit

type request = Pipe.read -> server -> (responder -> unit) -> unit

type endpoint = char * request
