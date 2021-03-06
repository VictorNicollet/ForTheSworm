type t 

exception ParseError of exn

val to_bytes : t -> string
val of_bytes : string -> t 

(* The full size of the blob, as stored, in bytes. *)
val bytes : t -> int

(* These functions assume that the channel is a file that contains
   the entire blob and nothing more. *)
val to_channel : out_channel -> t -> unit
val of_channel : in_channel -> t

val hash : t -> Key.t

val keys : t -> Key.t array
val data : t -> string

val make : ?keys:Key.t array -> string -> t

module Store : sig

  type store 
    
  val define : Store.store -> store
    
  val save : store -> t -> Key.t
  val load : store -> Key.t -> t option
  val find : store -> Key.t -> bool
    
end
