type store = Store.store

val save : store -> Blob.t -> Key.t
val load : store -> Key.t -> Blob.t option
val find : store -> Key.t -> bool
