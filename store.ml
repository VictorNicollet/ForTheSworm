module Inner = Store_inner

type store = Inner.store

let locks = Hashtbl.create 100
let mutex = Mutex.create ()

let writelock store key = 
  Mutex.lock mutex ;
  let inner = 
    try Hashtbl.find locks (store,key) 
    with Not_found -> 
      let inner = Mutex.create () in
      Hashtbl.add locks (store,key) inner ;
      inner
  in
  Mutex.unlock mutex ;
  Mutex.lock inner 

let readblock store key = 
  Mutex.lock mutex ;
  try let inner = Hashtbl.find locks (store,key) in
      Mutex.unlock mutex ;
      Mutex.lock inner ;
      Mutex.unlock inner
  with Not_found ->
    Mutex.unlock mutex

let writeunlock store key = 
  Mutex.lock mutex ;
  (try Mutex.unlock (Hashtbl.find locks (store,key)) with Not_found -> ()) ;
  Hashtbl.remove locks (store,key) ;
  Mutex.unlock mutex 

let save store key callback = 
  let channel = Event.new_channel () in
  let _ = Thread.create begin fun () -> 
    writelock store key ;
    let result = 
      try BatStd.Ok (Inner.save store key callback)
      with exn -> BatStd.Bad exn 
    in 
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
