module Name : sig

  type seg = [ `K of Key.t | `S of string ]
  type t  

  val to_bytes : t -> string
  val of_bytes : string -> t
  val bytes : t -> int 
  val hash : t -> Key.t 
  val make : seg list -> t 
  val read : t -> seg list
  val human_readable : t -> string  

end

module Store : sig

  type store
  val define : Store.store -> store

  val exists : store -> Key.t -> bool

  module Raw : sig 
    val create : store -> name:Name.t -> initial:Key.t -> Key.t option 
    val save   : store -> Key.t -> setTo:Key.t -> ifEqualTo:Key.t -> [ `OK | `CONFLICT of Key.t | `MISSING ]
    val load   : store -> Key.t -> Key.t option 
    val delete : store -> Key.t -> unit
  end

end
