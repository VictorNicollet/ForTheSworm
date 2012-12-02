type 'a t = {
  mutable value : ('a,exn) BatStd.result option ;
  attempt : unit -> unit
}

let make attempt = {
  value = None ;
  attempt 
}

let get r = 
  if r.value = None then r.attempt () ;
  r.value 

let set r a = 
  r.value <- Some a
