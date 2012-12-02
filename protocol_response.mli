type 'a t

val make : (unit -> unit) -> 'a t

val get : 'a t -> ('a,exn) BatStd.result option 
val set : 'a t -> ('a,exn) BatStd.result -> unit
