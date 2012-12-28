type 'a t 

val make : unit -> 'a t 

val add  : 'a t -> 'a -> int

val remove : 'a t -> int -> 'a option 

val clear : 'a t -> ('a -> unit) -> unit 

val size : 'a t -> int
