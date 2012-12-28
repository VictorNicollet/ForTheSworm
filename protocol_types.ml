type server = <
  save_blob  : Blob.t -> Key.t ;
  load_blob  : Key.t  -> Blob.t option ;
  new_stream : Pointer.Name.t -> Key.t option ;  
  add_events : Key.t  -> Key.t list -> int option ;
  del_stream : Key.t  -> unit ; 
  get_events : Key.t  -> int -> int -> Key.t list option ;
>

type responder = Pipe.write -> unit

type request = Pipe.read -> server -> (responder -> unit) -> unit

type endpoint = char * request
