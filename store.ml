module Inner = Store_inner

type store = Inner.store

let locks = Hashtbl.create 100
let mutex = Mtx.make "store"

let writelock store key = 
  Mtx.use mutex (lazy (
    try Hashtbl.find locks (store,key) 
    with Not_found -> 
      let inner = Mtx.make ("store:"^Key.short key) in
      Hashtbl.add locks (store,key) inner ;
      inner
  ))

let readblock store key = 
  let inner = Mtx.use mutex (lazy (
    try Some (Hashtbl.find locks (store,key))
    with Not_found -> None
  )) in
  match inner with None -> () | Some mutex -> Mtx.use mutex (lazy ()) 

let writeunlock store key = 
  Mtx.use mutex (lazy (Hashtbl.remove locks (store,key)))

let save store key contents = 
  let write chan = output_string chan contents in
  try 
    let result =
      Mtx.use (writelock store key) 
	(lazy (Inner.save store key write)) 
    in
    writeunlock store key ;
    result
  with exn ->
    writeunlock store key ;
    raise exn 
 
let load store key callback = 
  readblock store key ;
  Inner.load store key callback

let find store key = 
  readblock store key ;
  Inner.find store key
