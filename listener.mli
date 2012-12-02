type handler = Unix.sockaddr -> SocketStream.stream -> unit

val start : port:int -> max:int -> handler -> unit

val stop : unit -> unit
