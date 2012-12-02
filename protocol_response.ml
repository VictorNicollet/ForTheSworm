type 'a t = {
  mutable value : ('a,exn) BatStd.result option ;
  attempt : unit -> unit
}

let make attempt = {
  value = None ;
  attempt 
}

let poll r = 
  if r.value = None then r.attempt () ;
  r.value 

let rec get r = 
  match poll r with 
    | None -> get r
    | Some (BatStd.Bad exn) -> raise exn
    | Some (BatStd.Ok  value) -> value 

let set r a = 
  r.value <- Some a
