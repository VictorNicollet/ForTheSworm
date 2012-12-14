type store
val define : Store.store -> store
  
val exists : store -> Key.t -> bool
  
module Raw : sig 
  val create : store -> name:Pointer_name.t -> initial:Key.t -> Key.t option 
  val save   : store -> Key.t -> setTo:Key.t -> ifEqualTo:Key.t -> [ `OK | `CONFLICT of Key.t | `MISSING ]
  val load   : store -> Key.t -> Key.t option 
  val delete : store -> Key.t -> unit
end
