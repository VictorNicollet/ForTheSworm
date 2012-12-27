type store
val define : Store.store -> store
  
val exists : store -> Key.t -> bool
  
module Raw : sig 
  val create : store -> name:Pointer_name.t -> initial:Key.t -> Key.t option 
  val save   : store -> Key.t -> setTo:Key.t -> ifEqualTo:Key.t -> [ `OK | `CONFLICT of Key.t | `MISSING ]
  val load   : store -> Key.t -> Key.t option 
  val delete : store -> Key.t -> unit
end

module Stream : sig

  class type server = object
    method save_blob : Blob.t -> Key.t 
    method load_blob : Key.t -> Blob.t option 
  end 

  val create : store -> #server -> name:Pointer_name.t -> Key.t option 
  val add    : store -> #server -> Key.t -> Key.t list -> [ `OK of int | `MISSING ]
  val load   : store -> #server -> Key.t -> start:int -> count:int -> Key.t list option
  val delete : store -> Key.t -> unit
 
end 
