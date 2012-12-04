type t = { name : string ; mutex : Mutex.t }

type 'a section = 'a Lazy.t -> 'a

let make name = 
  let mutex = Mutex.create () in
  { name ; mutex }

let use mtx x = 
  Mutex.lock mtx.mutex ;
  try let y = Lazy.force x in 
      Mutex.unlock mtx.mutex ;
      y
  with exn ->
    Mutex.unlock mtx.mutex ;
    raise exn 
  

