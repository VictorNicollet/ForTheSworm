type seg = [ `K of Key.t | `S of string ]
type t  
val to_bytes : t -> string
val of_bytes : string -> t
val bytes : t -> int  
val hash : t -> Key.t 
val make : seg list -> t 
val read : t -> seg list
val human_readable : t -> string  
