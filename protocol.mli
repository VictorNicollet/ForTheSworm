type server = <
  save_blob : Blob.t -> Key.t ;
  load_blob : Key.t  -> Blob.t option ; 
>

val version : int
val parseNextRequest : Pipe.readwrite -> server -> unit

module Response : sig
  type 'a t 
  val poll : 'a t -> ('a,exn) BatStd.result option 
  val get : 'a t -> 'a 
end

module ClientKernel : sig
  type t 
  val make : Pipe.readwrite -> t
  val destroy : t -> unit
end

module Handshake : sig
  val send : ClientKernel.t -> version:int -> int Response.t
end

module SaveBlob : sig 
  val send : ClientKernel.t -> blob:Blob.t -> Key.t Response.t
end

module LoadBlob : sig
  val send : ClientKernel.t -> key:Key.t -> Blob.t option Response.t
end
