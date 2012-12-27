module Inner = Store_inner

type store = Inner.store

let locks = Hashtbl.create 100
let mutex = Mtx.make "store"

let writelock store key = 
  Mtx.use mutex (lazy (
    try Hashtbl.find locks (store,key) 
    with Not_found -> 
      let inner = Mtx.make ("store:"^Key.to_hex_short key) in
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

let writelocked store key code = 
  try 
    let result = Mtx.use (writelock store key) code in 
    writeunlock store key ;
    result
  with exn ->
    writeunlock store key ;
    raise exn 

let readlocked store key code = 
  readblock store key ; 
  Lazy.force code

let write contents chan =
  output_string chan contents

let save store key contents = 
  writelocked store key 
    (lazy (Inner.save store key (write contents))) 
 
let load store key callback = 
  readlocked store key 
    (lazy (Inner.load store key callback))

let find store key = 
  readlocked store key 
    (lazy (Inner.find store key))

let delete store key = 
  writelocked store key 
    (lazy (Inner.delete store key)) 

let create store key ~data ~meta = 
  writelocked store key 
    (lazy begin 
      if Inner.find store key then false else begin 
	Inner.save store key ~meta:true (write meta) ;
	Inner.save store key (write data) ;
	true
      end 
    end)

let access store key callback = 
  writelocked store key 
    (lazy begin 

      (* Pass the appropriate data to the processing callback *)
      let processed = Inner.load store key (fun data_chan -> 

	let meta = lazy (Inner.load store key (fun meta_chan ->
	  let length = in_channel_length meta_chan in 
	  let meta   = String.create length in 
	  really_input meta_chan meta 0 length ;
	  meta
	)) in 

	callback ~meta data_chan 
      ) in 

      match processed with 
	| None                -> None
	| Some (r, None)      -> Some r
	| Some (r, Some data) -> let () = Inner.save store key ~overwrite:true(write data) in
				 Some r

    end)
