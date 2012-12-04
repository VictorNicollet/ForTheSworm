type t 
type 'a section = 'a Lazy.t -> 'a

val make : string -> t
val use : t -> 'a section
