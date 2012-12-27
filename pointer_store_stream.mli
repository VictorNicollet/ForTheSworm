class type server = object
  method save_blob : Blob.t -> Key.t 
  method load_blob : Key.t -> Blob.t option 
end 

val create : Pointer_store_common.store -> #server -> name:Pointer_name.t -> Key.t option 
val add    : Pointer_store_common.store -> #server -> Key.t -> Key.t list -> [ `OK of int | `MISSING ]
val load   : Pointer_store_common.store -> #server -> Key.t -> start:int -> count:int -> Key.t list option
val delete : Pointer_store_common.store -> Key.t -> unit 
