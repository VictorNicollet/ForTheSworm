type handler = Unix.sockaddr -> Pipe.readwrite -> unit

val start : port:int -> max:int -> handler:handler -> unit

val stop : unit -> unit
