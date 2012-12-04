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

let save store key callback = 
  let channel = Event.new_channel () in
  let _ = Thread.create begin fun () -> 
    let result = Mtx.use (writelock store key) (lazy (
      try BatStd.Ok (Inner.save store key callback)
      with exn -> BatStd.Bad exn 
    )) in
    writeunlock store key ;
    Event.sync (Event.send channel result)
  end () in
  Event.receive channel
 
let load store key callback = 
  let channel = Event.new_channel () in
  let _ = Thread.create begin fun () ->
    readblock store key ;
    let result = 
      try BatStd.Ok (Inner.load store key callback)
      with exn -> BatStd.Bad exn 
    in
    Event.sync (Event.send channel result)    
  end () in
  Event.receive channel

let find store key = 
  let channel = Event.new_channel () in
  let _ = Thread.create begin fun () -> 
    readblock store key ;
    let result = 
      try BatStd.Ok (Inner.find store key)
      with exn -> BatStd.Bad exn
    in
    Event.sync (Event.send channel result) 
  end () in
  Event.receive channel
