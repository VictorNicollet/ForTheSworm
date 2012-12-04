type store = string

val save : store -> Key.t -> string -> unit
val load : store -> Key.t -> (in_channel -> 'a) -> 'a option
val find : store -> Key.t -> bool
