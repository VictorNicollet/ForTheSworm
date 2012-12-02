type 'a t = {
  mutable tbl : 'a option array ;
  mutable free : int list 
}

let make () = {
  tbl  = [| None ; None ; None ; None |] ;
  free = [ 0 ; 1 ; 2 ; 3 ]
}

let enlarge t = 
  if t.free = [] then begin
    let tbl = t.tbl in 
    let n   = Array.length tbl in 
    t.tbl  <- Array.init (n * 2) (fun i -> if i < n then tbl.(i) else None) ;
    t.free <- BatList.init n (fun i -> i + n) 
  end 

let add t x = 
  enlarge t ;
  match t.free with [] -> assert false | i :: free ->
    t.tbl.(i) <- Some x ;
    t.free <- free ;
    i

let remove t i = 
  let y = t.tbl.(i) in
  t.tbl.(i) <- None ;
  if y <> None then t.free <- i :: t.free ;
  y

let clear t f = 
  Array.iter (function 
    | None -> () 
    | Some x -> f x) t.tbl ;
  let n = make () in 
  t.tbl  <- n.tbl ;
  t.free <- n.free 
