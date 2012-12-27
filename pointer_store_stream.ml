open Pointer_store_common

module Meta = Pointer_store_meta
module Name = Pointer_name 

class type server = object
  method save_blob : Blob.t -> Key.t 
  method load_blob : Key.t -> Blob.t option 
end 

let create store server ~name = 
  None

let add store server key events = 
  `MISSING

let load store server key ~start ~count = 
  None

let delete store key = 
  () 
