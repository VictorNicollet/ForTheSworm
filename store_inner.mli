type store = string

val save : store -> Key.t -> (out_channel -> unit) -> unit
val load : store -> Key.t -> (in_channel -> 'a) -> 'a option 
val find : store -> Key.t -> bool 
