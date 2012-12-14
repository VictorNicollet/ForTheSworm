type store 

val define : Store.store -> store

val save : store -> Blob_common.t -> Key.t
val load : store -> Key.t -> Blob_common.t option
val find : store -> Key.t -> bool
