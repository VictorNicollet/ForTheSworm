type server = <
  save : string -> Key.t ;
>

type request = server -> SocketStream.write -> unit

val version : int
val parseNextRequest : SocketStream.read -> request

module Response : sig
  type 'a t 
  val get : 'a t -> ('a,exn) BatStd.result option 
end

module Handshake : sig
  val send : version:int -> SocketStream.write -> unit
  val recv : SocketStream.read -> int
end

module Save : sig 
  val send : data:string -> SocketStream.write -> unit
  val recv : SocketStream.read -> Key.t
end
