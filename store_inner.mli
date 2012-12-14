type store = string

val save : store -> Key.t -> ?meta:bool -> (out_channel -> unit) -> unit
val load : store -> Key.t -> ?meta:bool -> (in_channel -> 'a) -> 'a option 
val find : store -> Key.t -> bool 
val delete : store -> Key.t -> unit
