open Pointer_store_common

module Meta = Pointer_store_meta
module Name = Pointer_name 

class type server = object
  method save_blob : Blob.t -> Key.t 
  method load_blob : Key.t -> Blob.t option 
end 

let create store server ~name = 
  let key  = Name.hash name in
  let meta = Meta.(to_bytes { kind = `STREAM ; name = name }) in
  let tree = SeqTree.empty in 
  let blob = SeqTree.to_blob tree in 
  let tkey = server # save_blob blob in 
  let data = Key.to_bytes tkey in 
  if Store.create store key ~meta ~data then Some key else None

let add store server key events = 
  `MISSING

let load store server key ~start ~count = 
  None

let delete store key = 
  () 
