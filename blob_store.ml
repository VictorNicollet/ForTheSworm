module B = Blob_common 

type store = string

let define s = Filename.concat s "blob"

let save store blob = 
  let key   = B.hash blob in 
  let bytes = B.to_bytes blob in 
  Store.save store key bytes ;
  key

let load store key = 
  Store.load store key B.of_channel 

let find store key = 
  Store.find store key 
