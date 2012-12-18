type 'a t 

val last : 'a t -> int
val add  : 'a -> 'a t -> 'a t 

val split : 'a t -> [ `KEEP of 'a t | `SPLIT of 'a t * (Key.t -> 'a t) ] 

val range : 'a t -> int -> int -> (Key.t * int * int) list * ('a * int) list
