open Pointer_store_common

module Meta = Pointer_store_meta
module Name = Pointer_name

let create store ~name ~initial = 
  let key  = Name.hash name in
  let meta = Meta.(to_bytes { kind = `RAW ; name = name }) in 
  let data = Key.to_bytes initial in 
  if Store.create store key ~meta ~data then Some key else None

let save store key ~setTo ~ifEqualTo = 
  let result = Store.access store key (fun ~meta chan -> 
    let current = Key.of_channel chan in 
    if current = ifEqualTo then 
      `OK, Some (Key.to_bytes setTo)
    else
      `CONFLICT current, None
  ) in 

  match result with 
    | Some `OK             -> `OK
    | Some (`CONFLICT key) -> `CONFLICT key
    | None                 -> `MISSING

let load store key = 
  Store.load store key Key.of_channel 

let delete store key = 
  Store.delete store key 
