type server = <
  name : string
>

type request = server -> SocketStream.write -> unit

val version : int
val parseNextRequest : SocketStream.read -> request

module Handshake : sig
  val send : version:int -> SocketStream.write -> unit
  val recv : SocketStream.read -> int
end
