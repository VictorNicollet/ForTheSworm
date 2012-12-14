open Pointer_store_common

val create : store -> name:Pointer_name.t -> initial:Key.t -> Key.t option 
val save   : store -> Key.t -> setTo:Key.t -> ifEqualTo:Key.t -> [ `OK | `CONFLICT of Key.t | `MISSING ]
val load   : store -> Key.t -> Key.t option 
val delete : store -> Key.t -> unit
