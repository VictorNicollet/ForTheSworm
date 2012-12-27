open Pointer_store_common

class type server = object
  method save_blob : Blob.t -> Key.t 
  method load_blob : Key.t -> Blob.t option 
end 

val create : store -> #server -> name:Pointer_name.t -> Key.t option 
val add    : store -> #server -> Key.t -> Key.t list -> [ `OK of int | `MISSING ]
val load   : store -> #server -> Key.t -> start:int -> count:int -> Key.t list option
val delete : store -> Key.t -> unit 
