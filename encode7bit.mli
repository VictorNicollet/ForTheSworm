exception BadInput of exn 

val to_string : int -> string
val of_string : string -> int

val of_prefix : string -> int

val length : int -> int

val to_channel : out_channel -> int -> unit
val of_channel : in_channel -> int

val of_charStream : ('a -> char) -> 'a -> int
