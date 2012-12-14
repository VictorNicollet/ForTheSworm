type store = string

(* Generic functions *)

val find : store -> Key.t -> bool

(* Functions with blob semantics *)

val save : store -> Key.t -> string -> unit
val load : store -> Key.t -> (in_channel -> 'a) -> 'a option

(* Functions with pointer semantics *)

val create : store -> Key.t -> data:string -> meta:string -> bool 
val delete : store -> Key.t -> unit 

val access : 
     store
  -> Key.t
  -> (meta:string option Lazy.t -> in_channel -> 'a * string option)
  -> 'a option  
