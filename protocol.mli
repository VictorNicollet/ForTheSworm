type server = <
  save : string -> Key.t ;
>

val version : int
val parseNextRequest : SocketStream.stream -> server -> unit

module Response : sig
  type 'a t 
  val poll : 'a t -> ('a,exn) BatStd.result option 
  val get : 'a t -> 'a 
end

module ClientKernel : sig
  type t 
  val make : SocketStream.stream -> t
  val destroy : t -> unit
end

module Handshake : sig
  val send : ClientKernel.t -> version:int -> int Response.t
end

module Save : sig 
  val send : ClientKernel.t -> data:string -> Key.t Response.t
end
