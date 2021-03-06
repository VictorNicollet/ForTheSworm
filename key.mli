type t 

val of_bytes : string -> t
val to_bytes : t -> string

val of_channel : in_channel -> t

val of_sha1 : Sha1.t -> t 
val to_hex_short : t -> string

val to_hex : t -> string

val empty : t 

val bytes : int
