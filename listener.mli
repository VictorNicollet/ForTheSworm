type handler = Unix.sockaddr -> SocketStream.read -> SocketStream.write -> unit

val start : port:int -> max:int -> handler -> unit

val stop : unit -> unit
