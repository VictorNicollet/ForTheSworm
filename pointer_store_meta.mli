type kind = [`RAW|`STREAM]

type t = { kind : kind ; name : Pointer_name.t }

val of_channel : in_channel -> t option 

val of_bytes : string -> t option 
val to_bytes : t -> string
